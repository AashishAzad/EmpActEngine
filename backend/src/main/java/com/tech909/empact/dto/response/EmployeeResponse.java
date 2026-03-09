package com.tech909.empact.dto.response;

import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Employee Response DTO
 *
 * Safe representation of Employee entity for API responses.
 * Never exposes password or other sensitive fields.
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeResponse {

    private UUID id;
    private String employeeId;
    private String firstName;
    private String lastName;
    private String email;
    private UserRole role;
    private EmployeeStatus status;
    private String designation;
    private String department;
    private LocalDate dateOfJoining;
    private String qualification;
    private String phoneNumber;
    private String address;
    private String emergencyContact;
    private Integer casualLeaveBalance;
    private Integer sickLeaveBalance;
    private Integer allPurposeLeaveBalance;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime lastLogin;

    /**
     * Optional nested salary — only included when admin requests with includeSalary=true
     * Null otherwise to keep response lightweight.
     */
    private SalaryInfo salary;

    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SalaryInfo {
        private Double basicPay;
        private Double hra;
        private Double specialAllowance;
        private Double otherAllowances;
        private Double pf;
        private Double professionalTax;
        private Double otherDeductions;
        private Double grossPay;
        private Double netPay;
    }
}
