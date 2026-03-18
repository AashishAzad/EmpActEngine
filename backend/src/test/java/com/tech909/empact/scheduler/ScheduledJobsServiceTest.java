package com.tech909.empact.scheduler;

import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.NotificationRepository;
import com.tech909.empact.repository.PayslipRepository;
import com.tech909.empact.repository.SalaryRepository;
import com.tech909.empact.repository.UserRepository;
import com.tech909.empact.service.NotificationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ScheduledJobsServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private CompanyHolidayRepository holidayRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private SalaryRepository salaryRepository;

    @Mock
    private PayslipRepository payslipRepository;

    @InjectMocks
    private ScheduledJobsService scheduledJobsService;

    @Test
    void sendAttendanceReminder_skipsWhenTodayIsHoliday() {
        when(holidayRepository.existsByDate(LocalDate.now())).thenReturn(true);

        scheduledJobsService.sendAttendanceReminder();

        verify(userRepository, never()).findByStatus(EmployeeStatus.ACTIVE);
        verify(notificationService, never()).createSystemNotification(any(), any(), any(), any());
    }

    @Test
    void sendAttendanceReminder_notifiesOnlyEmployeesWithoutAttendance() {
        User userOne = buildUser(UUID.randomUUID(), "EMP001", UserRole.EMPLOYEE);
        User userTwo = buildUser(UUID.randomUUID(), "EMP002", UserRole.EMPLOYEE);

        when(holidayRepository.existsByDate(LocalDate.now())).thenReturn(false);
        when(userRepository.findByStatus(EmployeeStatus.ACTIVE)).thenReturn(List.of(userOne, userTwo));
        when(attendanceRepository.findEmployeeIdsWithAttendanceOnDate(LocalDate.now())).thenReturn(List.of(userOne.getId()));

        scheduledJobsService.sendAttendanceReminder();

        verify(notificationService).createSystemNotification(
                eq("ATTENDANCE_REMINDER"),
                eq("Attendance Reminder ⏰"),
                eq("Hi Test, you haven't marked your attendance today. Please mark it now."),
                eq(List.of(userTwo.getId()))
        );
    }

    @Test
    void resetLeaveBalances_resetsBalancesAndNotifiesEmployees() {
        User userOne = buildUser(UUID.randomUUID(), "EMP001", UserRole.EMPLOYEE);
        userOne.setCasualLeaveBalance(1);
        userOne.setSickLeaveBalance(2);
        userOne.setAllPurposeLeaveBalance(3);

        User userTwo = buildUser(UUID.randomUUID(), "EMP002", UserRole.ADMIN);
        userTwo.setCasualLeaveBalance(4);
        userTwo.setSickLeaveBalance(5);
        userTwo.setAllPurposeLeaveBalance(6);

        when(userRepository.findByStatus(EmployeeStatus.ACTIVE)).thenReturn(List.of(userOne, userTwo));

        scheduledJobsService.resetLeaveBalances();

        assertThat(userOne.getCasualLeaveBalance()).isEqualTo(8);
        assertThat(userOne.getSickLeaveBalance()).isEqualTo(8);
        assertThat(userOne.getAllPurposeLeaveBalance()).isEqualTo(10);
        assertThat(userTwo.getCasualLeaveBalance()).isEqualTo(8);

        verify(userRepository).saveAll(List.of(userOne, userTwo));
        verify(notificationService).createSystemNotification(
                eq("LEAVE_BALANCE_RESET"),
                eq("Leave Balance Reset 🎉"),
                eq("Your leave balances have been reset for the new year. Happy New Year!"),
                eq(List.of(userOne.getId(), userTwo.getId()))
        );
    }

    @Test
    void sendPayslipReminder_notifiesActiveAdminsWhenPendingPayslipsExist() {
        User admin = buildUser(UUID.randomUUID(), "ADM001", UserRole.ADMIN);
        LocalDate today = LocalDate.now();
        int lastMonth = today.getMonthValue() == 1 ? 12 : today.getMonthValue() - 1;
        int lastMonthYear = today.getMonthValue() == 1 ? today.getYear() - 1 : today.getYear();

        when(salaryRepository.count()).thenReturn(5L);
        when(payslipRepository.countByMonthAndYear(lastMonth, lastMonthYear)).thenReturn(3L);
        when(userRepository.findByRoleAndStatus(UserRole.ADMIN, EmployeeStatus.ACTIVE)).thenReturn(List.of(admin));

        scheduledJobsService.sendPayslipReminder();

        verify(notificationService).createSystemNotification(
                eq("PAYSLIP_REMINDER"),
                eq("Pending Payslips 📋"),
                eq("2 employees are pending payslip generation for " + lastMonth + "/" + lastMonthYear + ". Please generate them."),
                eq(List.of(admin.getId()))
        );
    }

    @Test
    void cleanOldNotifications_deletesNotificationsOlderThanThirtyDays() {
        scheduledJobsService.cleanOldNotifications();

        ArgumentCaptor<LocalDateTime> cutoffCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(notificationRepository).deleteByCreatedAtBefore(cutoffCaptor.capture());
        assertThat(cutoffCaptor.getValue()).isBefore(LocalDateTime.now().minusDays(29));
    }

    private User buildUser(UUID id, String employeeId, UserRole role) {
        User user = new User();
        user.setId(id);
        user.setEmployeeId(employeeId);
        user.setFirstName("Test");
        user.setLastName("User");
        user.setStatus(EmployeeStatus.ACTIVE);
        user.setRole(role);
        return user;
    }
}
