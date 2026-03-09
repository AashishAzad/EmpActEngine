package com.tech909.empact.controller;

import com.tech909.empact.scheduler.ScheduledJobsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Scheduled Jobs Controller
 * Base path: /scheduled-jobs (full path: /api/v1/scheduled-jobs)
 *
 * Admin-only manual triggers for cron jobs.
 * Useful for testing or running jobs outside their scheduled time.
 */
@RestController
@RequestMapping("/scheduled-jobs")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class ScheduledJobsController {

    private final ScheduledJobsService scheduledJobsService;

    /** POST /scheduled-jobs/trigger/attendance-reminder */
    @PostMapping("/trigger/attendance-reminder")
    public ResponseEntity<Map<String, String>> triggerAttendanceReminder() {
        scheduledJobsService.triggerAttendanceReminder();
        return ResponseEntity.ok(Map.of("message", "Attendance reminder job triggered"));
    }

    /** POST /scheduled-jobs/trigger/leave-balance-reset */
    @PostMapping("/trigger/leave-balance-reset")
    public ResponseEntity<Map<String, String>> triggerLeaveBalanceReset() {
        scheduledJobsService.triggerLeaveBalanceReset();
        return ResponseEntity.ok(Map.of("message", "Leave balance reset job triggered"));
    }

    /** POST /scheduled-jobs/trigger/payslip-reminder */
    @PostMapping("/trigger/payslip-reminder")
    public ResponseEntity<Map<String, String>> triggerPayslipReminder() {
        scheduledJobsService.triggerPayslipReminder();
        return ResponseEntity.ok(Map.of("message", "Payslip reminder job triggered"));
    }
}
