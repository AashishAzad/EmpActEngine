package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ActionManualAttendanceRequest;
import com.tech909.empact.dto.request.ManualAttendanceRequestDto;
import com.tech909.empact.dto.request.MarkAttendanceRequest;
import com.tech909.empact.dto.response.AttendanceResponse;
import com.tech909.empact.dto.response.AttendanceSummaryResponse;
import com.tech909.empact.dto.response.ManualAttendanceRequestResponse;
import com.tech909.empact.service.AttendanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Attendance Controller
 * Base path: /attendance (full path: /api/v1/attendance)
 */
@RestController
@RequestMapping("/attendance")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    /** POST /attendance/mark */
    @PostMapping("/mark")
    public ResponseEntity<AttendanceResponse> markAttendance(
            @Valid @RequestBody MarkAttendanceRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(attendanceService.markAttendance(userId, request));
    }

    /** GET /attendance/today — check if current user marked today */
    @GetMapping("/today")
    public ResponseEntity<Map<String, Object>> getTodayAttendance(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(attendanceService.getTodayAttendance(userId));
    }

    /**
     * GET /attendance/my-attendance?month=1&year=2026
     * Shortcut for current user's own attendance
     */
    @GetMapping("/my-attendance")
    public ResponseEntity<List<AttendanceResponse>> getMyAttendance(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(attendanceService.getAttendance(userId, month, year));
    }

    /**
     * GET /attendance?employeeId=&month=1&year=2026
     * Admin/Manager can view any employee's attendance
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<List<AttendanceResponse>> getAttendance(
            @RequestParam UUID employeeId,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {
        return ResponseEntity.ok(attendanceService.getAttendance(employeeId, month, year));
    }

    /**
     * GET /attendance/summary?month=1&year=2026
     * Monthly summary with statistics for current user
     */
    @GetMapping("/summary")
    public ResponseEntity<AttendanceSummaryResponse> getMonthlySummary(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam int month,
            @RequestParam int year) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(attendanceService.getMonthlySummary(userId, month, year));
    }

    /** POST /attendance/manual-request */
    @PostMapping("/manual-request")
    public ResponseEntity<ManualAttendanceRequestResponse> submitManualRequest(
            @Valid @RequestBody ManualAttendanceRequestDto request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(attendanceService.submitManualRequest(userId, request));
    }

    /** GET /attendance/manual-requests/pending — Admin/Manager */
    @GetMapping("/manual-requests/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<List<ManualAttendanceRequestResponse>> getPendingManualRequests() {
        return ResponseEntity.ok(attendanceService.getPendingManualRequests());
    }

    /** PATCH /attendance/manual-requests/{id}/action — Admin/Manager */
    @PatchMapping("/manual-requests/{id}/action")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ManualAttendanceRequestResponse> actionManualRequest(
            @PathVariable UUID id,
            @Valid @RequestBody ActionManualAttendanceRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID actionById = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(
                attendanceService.actionManualRequest(id, actionById, request));
    }
}
