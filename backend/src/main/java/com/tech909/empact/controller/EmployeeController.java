package com.tech909.empact.controller;

import com.tech909.empact.dto.request.CreateEmployeeRequest;
import com.tech909.empact.dto.request.UpdateEmployeeRequest;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.service.EmployeeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Employee Controller
 *
 * Base path: /employees (full path: /api/v1/employees)
 *
 * RBAC via @PreAuthorize:
 * - hasRole('ADMIN')           → Admin only
 * - hasAnyRole('ADMIN','MANAGER') → Admin or Manager
 * - (no annotation)            → any authenticated user
 */
@RestController
@RequestMapping("/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    /** POST /employees — Admin only */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EmployeeResponse> createEmployee(
            @Valid @RequestBody CreateEmployeeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(employeeService.createEmployee(request));
    }

    /**
     * GET /employees?search=&role=&status=&department=&page=1&limit=10
     * Admin/Manager
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<PagedResponse<EmployeeResponse>> getEmployees(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) EmployeeStatus status,
            @RequestParam(required = false) String department,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(
                employeeService.getEmployees(search, role, status, department, page, limit));
    }

    /** GET /employees/statistics — Admin/Manager */
    @GetMapping("/statistics")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        return ResponseEntity.ok(employeeService.getStatistics());
    }

    /** GET /employees/by-employee-id/EMP001 */
    @GetMapping("/by-employee-id/{employeeId}")
    public ResponseEntity<EmployeeResponse> getByEmployeeId(
            @PathVariable String employeeId) {
        return ResponseEntity.ok(employeeService.getEmployeeByEmployeeId(employeeId));
    }

    /** GET /employees/{id}?includeSalary=true */
    @GetMapping("/{id}")
    public ResponseEntity<EmployeeResponse> getById(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "false") boolean includeSalary) {
        return ResponseEntity.ok(employeeService.getEmployeeById(id, includeSalary));
    }

    /** PATCH /employees/{id} — Admin only */
    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EmployeeResponse> updateEmployee(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateEmployeeRequest request) {
        return ResponseEntity.ok(employeeService.updateEmployee(id, request));
    }

    /** DELETE /employees/{id} — soft delete (TERMINATED) — Admin only */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> softDelete(@PathVariable UUID id) {
        return ResponseEntity.ok(employeeService.softDeleteEmployee(id));
    }

    /** DELETE /employees/{id}/permanent — hard delete — Admin only */
    @DeleteMapping("/{id}/permanent")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> hardDelete(@PathVariable UUID id) {
        return ResponseEntity.ok(employeeService.hardDeleteEmployee(id));
    }
}
