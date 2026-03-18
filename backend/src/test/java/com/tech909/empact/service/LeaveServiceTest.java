package com.tech909.empact.service;

import com.tech909.empact.dto.request.ActionLeaveRequest;
import com.tech909.empact.dto.request.ApplyLeaveRequest;
import com.tech909.empact.dto.response.LeaveResponse;
import com.tech909.empact.entity.Attendance;
import com.tech909.empact.entity.CompanyHoliday;
import com.tech909.empact.entity.Leave;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.LeaveRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LeaveServiceTest {

    @Mock
    private LeaveRepository leaveRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private CompanyHolidayRepository holidayRepository;

    @InjectMocks
    private LeaveService leaveService;

    @Test
    void applyLeave_withPastStartDate_throwsBusinessException() {
        ApplyLeaveRequest request = new ApplyLeaveRequest();
        request.setStartDate(LocalDate.now().minusDays(1));
        request.setEndDate(LocalDate.now());

        assertThatThrownBy(() -> leaveService.applyLeave(UUID.randomUUID(), request))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Leave start date cannot be in the past");
    }

    @Test
    void applyLeave_withInsufficientBalance_throwsBusinessException() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, UserRole.EMPLOYEE);
        user.setCasualLeaveBalance(1);

        ApplyLeaveRequest request = new ApplyLeaveRequest();
        request.setLeaveType(LeaveType.CASUAL);
        request.setStartDate(nextWeekday(LocalDate.now().plusDays(1)));
        request.setEndDate(nextWeekday(request.getStartDate().plusDays(1)));
        request.setContactNumber("9999999999");
        request.setContactEmail("leave@example.com");
        request.setRemarks("Family work");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(holidayRepository.findByDateBetween(request.getStartDate(), request.getEndDate())).thenReturn(List.of());

        assertThatThrownBy(() -> leaveService.applyLeave(userId, request))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Insufficient CASUAL leave balance");
    }

    @Test
    void applyLeave_successfullySavesPendingLeaveWithWorkingDayCount() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, UserRole.EMPLOYEE);
        user.setCasualLeaveBalance(10);

        LocalDate startDate = LocalDate.of(2026, 3, 23);
        LocalDate endDate = LocalDate.of(2026, 3, 25);
        CompanyHoliday holiday = new CompanyHoliday();
        holiday.setDate(LocalDate.of(2026, 3, 24));

        ApplyLeaveRequest request = new ApplyLeaveRequest();
        request.setLeaveType(LeaveType.CASUAL);
        request.setStartDate(startDate);
        request.setEndDate(endDate);
        request.setContactNumber("9999999999");
        request.setContactEmail("leave@example.com");
        request.setRemarks("Personal work");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(holidayRepository.findByDateBetween(startDate, endDate)).thenReturn(List.of(holiday));
        when(leaveRepository.save(any(Leave.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LeaveResponse response = leaveService.applyLeave(userId, request);

        ArgumentCaptor<Leave> leaveCaptor = ArgumentCaptor.forClass(Leave.class);
        verify(leaveRepository).save(leaveCaptor.capture());
        Leave savedLeave = leaveCaptor.getValue();

        assertThat(savedLeave.getNumberOfDays()).isEqualTo(2);
        assertThat(savedLeave.getStatus()).isEqualTo(LeaveStatus.PENDING);
        assertThat(response.getNumberOfDays()).isEqualTo(2);
        assertThat(response.getStatus()).isEqualTo(LeaveStatus.PENDING);
    }

    @Test
    void actionLeave_byManagerForNonEmployee_throwsBusinessException() {
        UUID leaveId = UUID.randomUUID();
        User managerUser = buildUser(UUID.randomUUID(), UserRole.MANAGER);
        Leave leave = Leave.builder()
                .id(leaveId)
                .employee(managerUser)
                .status(LeaveStatus.PENDING)
                .leaveType(LeaveType.CASUAL)
                .numberOfDays(1)
                .startDate(LocalDate.of(2026, 3, 23))
                .endDate(LocalDate.of(2026, 3, 23))
                .build();

        ActionLeaveRequest request = new ActionLeaveRequest();
        request.setStatus(LeaveStatus.APPROVED);

        when(leaveRepository.findById(leaveId)).thenReturn(Optional.of(leave));

        assertThatThrownBy(() -> leaveService.actionLeave(
                leaveId, UUID.randomUUID(), request, UserRole.MANAGER))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Managers can only action leaves of employees");
    }

    @Test
    void actionLeave_whenApproved_deductsBalanceAndCreatesAttendanceForWorkingDays() {
        UUID leaveId = UUID.randomUUID();
        UUID approverId = UUID.randomUUID();
        UUID employeeId = UUID.randomUUID();
        User employee = buildUser(employeeId, UserRole.EMPLOYEE);
        employee.setCasualLeaveBalance(8);
        User approver = buildUser(approverId, UserRole.ADMIN);

        Leave leave = Leave.builder()
                .id(leaveId)
                .employee(employee)
                .status(LeaveStatus.PENDING)
                .leaveType(LeaveType.CASUAL)
                .numberOfDays(2)
                .startDate(LocalDate.of(2026, 3, 23))
                .endDate(LocalDate.of(2026, 3, 25))
                .build();

        CompanyHoliday holiday = new CompanyHoliday();
        holiday.setDate(LocalDate.of(2026, 3, 24));

        ActionLeaveRequest request = new ActionLeaveRequest();
        request.setStatus(LeaveStatus.APPROVED);
        request.setActionRemarks("Approved");

        when(leaveRepository.findById(leaveId)).thenReturn(Optional.of(leave));
        when(userRepository.findById(approverId)).thenReturn(Optional.of(approver));
        when(leaveRepository.save(leave)).thenReturn(leave);
        when(holidayRepository.findByDateBetween(leave.getStartDate(), leave.getEndDate())).thenReturn(List.of(holiday));
        when(attendanceRepository.existsByEmployee_IdAndDate(employeeId, LocalDate.of(2026, 3, 23))).thenReturn(false);
        when(attendanceRepository.existsByEmployee_IdAndDate(employeeId, LocalDate.of(2026, 3, 25))).thenReturn(false);

        LeaveResponse response = leaveService.actionLeave(leaveId, approverId, request, UserRole.ADMIN);

        verify(userRepository).save(employee);
        assertThat(employee.getCasualLeaveBalance()).isEqualTo(6);

        ArgumentCaptor<Attendance> attendanceCaptor = ArgumentCaptor.forClass(Attendance.class);
        verify(attendanceRepository, times(2)).save(attendanceCaptor.capture());
        List<Attendance> attendanceRecords = attendanceCaptor.getAllValues();
        assertThat(attendanceRecords).allMatch(a -> a.getStatus() == AttendanceStatus.LEAVE);
        assertThat(attendanceRecords).extracting(Attendance::getDate)
                .containsExactly(LocalDate.of(2026, 3, 23), LocalDate.of(2026, 3, 25));
        assertThat(response.getStatus()).isEqualTo(LeaveStatus.APPROVED);
        assertThat(response.getActionRemarks()).isEqualTo("Approved");
    }

    @Test
    void getPendingLeaves_forManager_filtersEmployeeRole() {
        User employee = buildUser(UUID.randomUUID(), UserRole.EMPLOYEE);
        Leave leave = Leave.builder()
                .id(UUID.randomUUID())
                .employee(employee)
                .status(LeaveStatus.PENDING)
                .leaveType(LeaveType.SICK)
                .startDate(LocalDate.of(2026, 3, 23))
                .endDate(LocalDate.of(2026, 3, 23))
                .numberOfDays(1)
                .build();

        when(leaveRepository.findPendingLeaves("EMPLOYEE")).thenReturn(List.of(leave));

        List<LeaveResponse> result = leaveService.getPendingLeaves(UserRole.MANAGER);

        assertThat(result).hasSize(1);
        verify(leaveRepository).findPendingLeaves("EMPLOYEE");
    }

    @Test
    void getMyLeaves_returnsMappedResponses() {
        UUID userId = UUID.randomUUID();
        User employee = buildUser(userId, UserRole.EMPLOYEE);
        Leave leave = Leave.builder()
                .id(UUID.randomUUID())
                .employee(employee)
                .status(LeaveStatus.APPROVED)
                .leaveType(LeaveType.ALL_PURPOSE)
                .startDate(LocalDate.of(2026, 4, 1))
                .endDate(LocalDate.of(2026, 4, 2))
                .numberOfDays(2)
                .build();

        when(leaveRepository.findLeavesFiltered(eq(userId), eq(null), eq(null), eq(null), eq(null), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(leave)));

        List<LeaveResponse> result = leaveService.getMyLeaves(userId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getLeaveType()).isEqualTo(LeaveType.ALL_PURPOSE);
    }

    private User buildUser(UUID userId, UserRole role) {
        User user = new User();
        user.setId(userId);
        user.setEmployeeId("EMP-" + userId.toString().substring(0, 5));
        user.setFirstName("Test");
        user.setLastName("User");
        user.setDepartment("Tech");
        user.setRole(role);
        user.setCasualLeaveBalance(8);
        user.setSickLeaveBalance(8);
        user.setAllPurposeLeaveBalance(10);
        return user;
    }

    private LocalDate nextWeekday(LocalDate date) {
        LocalDate current = date;
        while (current.getDayOfWeek().getValue() >= 6) {
            current = current.plusDays(1);
        }
        return current;
    }
}
