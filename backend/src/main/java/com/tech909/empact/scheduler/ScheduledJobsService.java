package com.tech909.empact.scheduler;

import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.repository.*;
import com.tech909.empact.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Scheduled Jobs Service
 *
 * Automated background tasks using Spring's @Scheduled annotation.
 * Replaces NestJS's @nestjs/schedule cron jobs.
 *
 * All times in IST (Asia/Kolkata) — set in cron zone parameter.
 *
 * Jobs:
 * 1. Attendance Reminder    — 5 PM Mon-Fri
 * 2. Leave Balance Reset    — Midnight Jan 1st
 * 3. Payslip Reminder       — 9 AM on 5th of every month
 * 4. Notification Cleanup   — 2 AM every Sunday
 *
 * Cron format: second minute hour dayOfMonth month dayOfWeek
 *
 * Design Pattern: Template Method
 * Each job follows: check conditions → query DB → perform action → log result
 *
 * Note: @EnableScheduling is in EmployeeActivityApplication main class
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ScheduledJobsService {

    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final CompanyHolidayRepository holidayRepository;
    private final NotificationService notificationService;
    private final NotificationRepository notificationRepository;
    private final SalaryRepository salaryRepository;
    private final PayslipRepository payslipRepository;

    // ─────────────────────────────────────────────────────────────────────────
    // Job 1: Attendance Reminder — 5 PM, Monday to Friday
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cron: 0 0 17 * * MON-FRI  (5:00 PM, Mon-Fri, IST)
     *
     * Finds employees who have NOT marked attendance today
     * and sends them a reminder notification.
     *
     * Algorithm:
     * 1. Skip if today is a company holiday
     * 2. Get all active employee IDs → HashSet (O(n) build)
     * 3. Get IDs of employees who marked attendance today → HashSet
     * 4. Compute difference: absent = allEmployees - markedEmployees
     *    (Set difference — O(n) time, O(n) space)
     * 5. Send notification to each absent employee
     */
    @Scheduled(cron = "0 0 17 * * MON-FRI", zone = "Asia/Kolkata")
    @Transactional
    public void sendAttendanceReminder() {
        log.info("⏰ Running attendance reminder job");

        LocalDate today = LocalDate.now();

        // Skip if company holiday
        if (holidayRepository.existsByDate(today)) {
            log.info("⏭️ Skipping attendance reminder — today is a company holiday");
            return;
        }

        // All active employees — build into a Set
        List<User> activeEmployees = userRepository.findByStatus(EmployeeStatus.ACTIVE);

        // IDs of employees who marked attendance today — HashSet for O(1) lookup
        Set<UUID> markedIds = new HashSet<>(
                attendanceRepository.findEmployeeIdsWithAttendanceOnDate(today)
        );

        // Set difference: employees who have NOT marked attendance
        List<User> notMarked = activeEmployees.stream()
                .filter(emp -> !markedIds.contains(emp.getId()))
                .toList();

        if (notMarked.isEmpty()) {
            log.info("✅ All employees have marked attendance today");
            return;
        }

        // Send individual notification to each employee who hasn't marked
        for (User employee : notMarked) {
            notificationService.createSystemNotification(
                    "ATTENDANCE_REMINDER",
                    "Attendance Reminder ⏰",
                    "Hi " + employee.getFirstName()
                            + ", you haven't marked your attendance today. Please mark it now.",
                    List.of(employee.getId())
            );
        }

        log.info("📢 Attendance reminder sent to {} employees", notMarked.size());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Job 2: Leave Balance Reset — Midnight, January 1st (New Year)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cron: 0 0 0 1 1 *  (Midnight, Jan 1st, every year, IST)
     *
     * Resets all active employees' leave balances to defaults:
     * - Casual Leave:      8 days
     * - Sick Leave:        8 days
     * - All Purpose Leave: 10 days
     *
     * Also sends a notification to all employees.
     */
    @Scheduled(cron = "0 0 0 1 1 *", zone = "Asia/Kolkata")
    @Transactional
    public void resetLeaveBalances() {
        log.info("🔄 Running yearly leave balance reset job");

        List<User> activeEmployees = userRepository.findByStatus(EmployeeStatus.ACTIVE);

        // Reset balances for all active employees
        activeEmployees.forEach(emp -> {
            emp.setCasualLeaveBalance(8);
            emp.setSickLeaveBalance(8);
            emp.setAllPurposeLeaveBalance(10);
        });
        userRepository.saveAll(activeEmployees);

        log.info("✅ Leave balances reset for {} employees", activeEmployees.size());

        // Notify all employees
        List<UUID> employeeIds = activeEmployees.stream()
                .map(User::getId).toList();

        if (!employeeIds.isEmpty()) {
            notificationService.createSystemNotification(
                    "LEAVE_BALANCE_RESET",
                    "Leave Balance Reset 🎉",
                    "Your leave balances have been reset for the new year. Happy New Year!",
                    employeeIds
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Job 3: Payslip Reminder — 9 AM on 5th of every month
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cron: 0 0 9 5 * *  (9 AM on 5th of every month, IST)
     *
     * Checks if payslips have been generated for last month.
     * If any are pending, notifies all admins.
     *
     * Algorithm:
     * 1. Get all employees with salary configured
     * 2. Get IDs of employees who have payslip for last month → HashSet
     * 3. Difference = employees without payslip
     * 4. If count > 0, notify admins
     */
    @Scheduled(cron = "0 0 9 5 * *", zone = "Asia/Kolkata")
    @Transactional
    public void sendPayslipReminder() {
        log.info("💰 Running payslip reminder job");

        // Determine last month
        LocalDate today = LocalDate.now();
        int lastMonth = today.getMonthValue() == 1 ? 12 : today.getMonthValue() - 1;
        int lastMonthYear = today.getMonthValue() == 1
                ? today.getYear() - 1 : today.getYear();

        long totalWithSalary    = salaryRepository.count();
        long payslipsLastMonth  = payslipRepository.countByMonthAndYear(lastMonth, lastMonthYear);
        long pendingCount       = totalWithSalary - payslipsLastMonth;

        if (pendingCount <= 0) {
            log.info("✅ All payslips generated for {}/{}", lastMonth, lastMonthYear);
            return;
        }

        // Get all admins and notify them
        List<UUID> adminIds = userRepository
                .findByRoleAndStatus(UserRole.ADMIN, EmployeeStatus.ACTIVE)
                .stream().map(User::getId).toList();

        if (!adminIds.isEmpty()) {
            notificationService.createSystemNotification(
                    "PAYSLIP_REMINDER",
                    "Pending Payslips 📋",
                    pendingCount + " employees are pending payslip generation for "
                            + lastMonth + "/" + lastMonthYear + ". Please generate them.",
                    adminIds
            );
            log.info("📧 Payslip reminder sent to {} admins ({} pending)",
                    adminIds.size(), pendingCount);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Job 4: Notification Cleanup — 2 AM every Sunday
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Cron: 0 0 2 * * SUN  (2 AM every Sunday, IST)
     *
     * Deletes notifications older than 30 days.
     * JPA cascade handles deletion of associated NotificationReceipt records.
     *
     * This keeps the notification table lean and prevents unbounded growth.
     */
    @Scheduled(cron = "0 0 2 * * SUN", zone = "Asia/Kolkata")
    @Transactional
    public void cleanOldNotifications() {
        log.info("🧹 Running notification cleanup job");

        LocalDateTime cutoff = LocalDateTime.now().minusDays(30);
        notificationRepository.deleteByCreatedAtBefore(cutoff);

        log.info("🗑️ Deleted notifications older than 30 days (before {})", cutoff);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Manual Trigger Methods (for POST /scheduled-jobs/trigger/*)
    // ─────────────────────────────────────────────────────────────────────────

    /** Manually trigger attendance reminder (Admin test endpoint) */
    public void triggerAttendanceReminder() {
        log.info("🔧 Manually triggered: attendance reminder");
        sendAttendanceReminder();
    }

    /** Manually trigger leave balance reset (Admin — use with caution!) */
    public void triggerLeaveBalanceReset() {
        log.info("🔧 Manually triggered: leave balance reset");
        resetLeaveBalances();
    }

    /** Manually trigger payslip reminder */
    public void triggerPayslipReminder() {
        log.info("🔧 Manually triggered: payslip reminder");
        sendPayslipReminder();
    }
}
