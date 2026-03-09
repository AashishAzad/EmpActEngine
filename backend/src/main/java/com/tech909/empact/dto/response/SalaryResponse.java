package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class SalaryResponse {
    private UUID id;
    private UUID employeeId;
    private EmployeeInfo employee;
    private Double basicPay;
    private Double hra;
    private Double specialAllowance;
    private Double otherAllowances;
    private Double pf;
    private Double professionalTax;
    private Double otherDeductions;
    private Double grossPay;
    private Double netPay;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class EmployeeInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
        private String designation;
    }
}
