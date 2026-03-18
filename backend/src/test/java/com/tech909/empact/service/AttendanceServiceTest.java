package com.tech909.empact.service;

import com.tech909.empact.dto.request.ActionManualAttendanceRequest;
import com.tech909.empact.dto.request.ManualAttendanceRequestDto;
import com.tech909.empact.dto.response.ManualAttendanceRequestResponse;
import com.tech909.empact.entity.Attendance;
import com.tech909.empact.entity.ManualAttendanceRequest;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.ManualAttendanceRequestRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AttendanceServiceTest {

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private ManualAttendanceRequestRepository manualAttendanceRequestRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CompanyHolidayRepository holidayRepository;

    @InjectMocks
    private AttendanceService attendanceService;

    @Test
    void getTodayAttendance_whenAbsent_returnsMarkedFalse() {
        UUID userId = UUID.randomUUID();
        when(attendanceRepository.findByEmployee_IdAndDate(userId, LocalDate.now())).thenReturn(Optional.empty());

        Map<String, Object> response = attendanceService.getTodayAttendance(userId);

        assertThat(response).containsEntry("marked", false);
    }

    @Test
    void submitManualRequest_forFutureDate_throwsBusinessException() {
        UUID userId = UUID.randomUUID();
        ManualAttendanceRequestDto request = new ManualAttendanceRequestDto();
        request.setRequestDate(LocalDate.now().plusDays(1));
        request.setReason("Missed due to network issue");

        when(userRepository.findById(userId)).thenReturn(Optional.of(buildUser(userId, "EMP001")));

        assertThatThrownBy(() -> attendanceService.submitManualRequest(userId, request))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Manual attendance request can only be for past dates");
    }

    @Test
    void actionManualRequest_whenApproved_createsManualApprovedAttendance() {
        UUID requestId = UUID.randomUUID();
        UUID approverId = UUID.randomUUID();
        UUID employeeId = UUID.randomUUID();
        LocalDate requestDate = LocalDate.now().minusDays(2);

        User employee = buildUser(employeeId, "EMP001");
        User approver = buildUser(approverId, "ADM001");

        ManualAttendanceRequest manualRequest = ManualAttendanceRequest.builder()
                .id(requestId)
                .employee(employee)
                .requestDate(requestDate)
                .reason("Forgot to mark")
                .status(LeaveStatus.PENDING)
                .build();

        ActionManualAttendanceRequest actionRequest = new ActionManualAttendanceRequest();
        actionRequest.setAction(LeaveStatus.APPROVED);
        actionRequest.setRemarks("Approved");

        when(manualAttendanceRequestRepository.findById(requestId)).thenReturn(Optional.of(manualRequest));
        when(userRepository.findById(approverId)).thenReturn(Optional.of(approver));
        when(manualAttendanceRequestRepository.save(manualRequest)).thenReturn(manualRequest);
        when(attendanceRepository.existsByEmployee_IdAndDate(employeeId, requestDate)).thenReturn(false);

        ManualAttendanceRequestResponse response =
                attendanceService.actionManualRequest(requestId, approverId, actionRequest);

        ArgumentCaptor<Attendance> attendanceCaptor = ArgumentCaptor.forClass(Attendance.class);
        verify(attendanceRepository, times(1)).save(attendanceCaptor.capture());

        Attendance createdAttendance = attendanceCaptor.getValue();
        assertThat(createdAttendance.getEmployee()).isEqualTo(employee);
        assertThat(createdAttendance.getDate()).isEqualTo(requestDate);
        assertThat(createdAttendance.getStatus()).isEqualTo(AttendanceStatus.MANUAL_APPROVED);
        assertThat(response.getStatus()).isEqualTo(LeaveStatus.APPROVED);
        assertThat(response.getRemarks()).isEqualTo("Approved");
    }

    private User buildUser(UUID userId, String employeeCode) {
        User user = new User();
        user.setId(userId);
        user.setEmployeeId(employeeCode);
        user.setFirstName("Test");
        user.setLastName("User");
        return user;
    }
}
