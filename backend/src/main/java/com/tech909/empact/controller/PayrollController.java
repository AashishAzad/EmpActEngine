package com.tech909.empact.controller;

import com.tech909.empact.dto.request.GeneratePayslipRequest;
import com.tech909.empact.dto.request.UpsertSalaryRequest;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.dto.response.PayslipResponse;
import com.tech909.empact.dto.response.SalaryResponse;
import com.tech909.empact.service.PayrollService;
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
 * Payroll Controller
 * Base path: /payroll (full path: /api/v1/payroll)
 */
@RestController
@RequestMapping("/payroll")
@RequiredArgsConstructor
public class PayrollController {

    private final PayrollService payrollService;

    /** POST /payroll/salary — Admin only */
    @PostMapping("/salary")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SalaryResponse> upsertSalary(
            @Valid @RequestBody UpsertSalaryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(payrollService.upsertSalary(request));
    }

    /** PUT /payroll/salary/{employeeId} — Admin only (alias) */
    @PutMapping("/salary/{employeeId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SalaryResponse> updateSalary(
            @PathVariable UUID employeeId,
            @Valid @RequestBody UpsertSalaryRequest request) {
        request.setEmployeeId(employeeId);
        return ResponseEntity.ok(payrollService.upsertSalary(request));
    }

    /** POST /payroll/generate-payslip — Admin only */
    @PostMapping("/generate-payslip")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PayslipResponse> generatePayslip(
            @Valid @RequestBody GeneratePayslipRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(payrollService.generatePayslip(request));
    }

    /** GET /payroll/my-salary */
    @GetMapping("/my-salary")
    public ResponseEntity<Map<String, Object>> getMySalary(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(payrollService.getMySalary(userId));
    }

    /** GET /payroll/salary/{employeeId} — Admin/Manager */
    @GetMapping("/salary/{employeeId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<SalaryResponse> getSalary(@PathVariable UUID employeeId) {
        return ResponseEntity.ok(payrollService.getSalary(employeeId));
    }

    /** GET /payroll/my-payslips?month=&year=&page=1&limit=10 */
    @GetMapping("/my-payslips")
    public ResponseEntity<PagedResponse<PayslipResponse>> getMyPayslips(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(payrollService.getPayslips(userId, month, year, page, limit));
    }

    /** GET /payroll/my-recent-payslips — last 3 payslips */
    @GetMapping("/my-recent-payslips")
    public ResponseEntity<List<PayslipResponse>> getMyRecentPayslips(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(payrollService.getMyRecentPayslips(userId));
    }

    /** GET /payroll/payslips?employeeId=&month=&year=&page=1 — Admin/Manager */
    @GetMapping("/payslips")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<PagedResponse<PayslipResponse>> getPayslips(
            @RequestParam(required = false) UUID employeeId,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(payrollService.getPayslips(employeeId, month, year, page, limit));
    }

    /** GET /payroll/statistics — Admin only */
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        return ResponseEntity.ok(payrollService.getStatistics());
    }
}