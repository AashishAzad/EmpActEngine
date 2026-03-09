package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ActionLeaveRequest;
import com.tech909.empact.dto.request.ApplyLeaveRequest;
import com.tech909.empact.dto.response.LeaveBalanceResponse;
import com.tech909.empact.dto.response.LeaveResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.service.LeaveService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Leave Controller
 * Base path: /leaves (full path: /api/v1/leaves)
 */
@RestController
@RequestMapping("/leaves")
@RequiredArgsConstructor
public class LeaveController {

    private final LeaveService leaveService;

    /** POST /leaves — apply for leave */
    @PostMapping
    public ResponseEntity<LeaveResponse> applyLeave(
            @Valid @RequestBody ApplyLeaveRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(leaveService.applyLeave(userId, request));
    }

    /** GET /leaves/my-leaves */
    @GetMapping("/my-leaves")
    public ResponseEntity<List<LeaveResponse>> getMyLeaves(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(leaveService.getMyLeaves(userId));
    }

    /** GET /leaves/my-balance */
    @GetMapping("/my-balance")
    public ResponseEntity<LeaveBalanceResponse> getMyBalance(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(leaveService.getMyBalance(userId));
    }

    /** GET /leaves/pending — Admin/Manager */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<List<LeaveResponse>> getPendingLeaves(
            @AuthenticationPrincipal UserDetails userDetails) {
        // Extract role from Spring Security authorities
        UserRole actorRole = userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))
                ? UserRole.ADMIN : UserRole.MANAGER;
        return ResponseEntity.ok(leaveService.getPendingLeaves(actorRole));
    }

    /** GET /leaves/statistics — Admin/Manager */
    @GetMapping("/statistics")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        return ResponseEntity.ok(leaveService.getStatistics());
    }

    /** GET /leaves/balance/{employeeId} — Admin/Manager */
    @GetMapping("/balance/{employeeId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<LeaveBalanceResponse> getBalanceForEmployee(
            @PathVariable UUID employeeId) {
        return ResponseEntity.ok(leaveService.getBalanceForEmployee(employeeId));
    }

    /**
     * GET /leaves?employeeId=&status=&leaveType=&startDate=&endDate=&page=1&limit=10
     * Admin/Manager
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<PagedResponse<LeaveResponse>> getLeaves(
            @RequestParam(required = false) UUID employeeId,
            @RequestParam(required = false) LeaveStatus status,
            @RequestParam(required = false) LeaveType leaveType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(
                leaveService.getLeaves(employeeId, status, leaveType, startDate, endDate, page, limit));
    }

    /** PATCH /leaves/{id}/action — Admin/Manager */
    @PatchMapping("/{id}/action")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<LeaveResponse> actionLeave(
            @PathVariable UUID id,
            @Valid @RequestBody ActionLeaveRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID actionById = UUID.fromString(userDetails.getUsername());
        UserRole actorRole = userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))
                ? UserRole.ADMIN : UserRole.MANAGER;
        return ResponseEntity.ok(leaveService.actionLeave(id, actionById, request, actorRole));
    }

    /** PATCH /leaves/{id}/approve — convenience route */
    @PatchMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<LeaveResponse> approveLeave(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID actionById = UUID.fromString(userDetails.getUsername());
        UserRole actorRole = userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))
                ? UserRole.ADMIN : UserRole.MANAGER;
        ActionLeaveRequest req = new ActionLeaveRequest();
        req.setStatus(LeaveStatus.APPROVED);
        return ResponseEntity.ok(leaveService.actionLeave(id, actionById, req, actorRole));
    }

    /** PATCH /leaves/{id}/reject — convenience route */
    @PatchMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<LeaveResponse> rejectLeave(
            @PathVariable UUID id,
            @RequestBody(required = false) ActionLeaveRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID actionById = UUID.fromString(userDetails.getUsername());
        UserRole actorRole = userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))
                ? UserRole.ADMIN : UserRole.MANAGER;
        if (request == null) request = new ActionLeaveRequest();
        request.setStatus(LeaveStatus.REJECTED);
        return ResponseEntity.ok(leaveService.actionLeave(id, actionById, request, actorRole));
    }
}
