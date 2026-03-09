package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class PayslipResponse {
    private UUID id;
    private UUID employeeId;
    private EmployeeInfo employee;
    private Integer month;
    private Integer year;
    private Double basicPay;
    private Double hra;
    private Double specialAllowance;
    private Double otherAllowances;
    private Double pf;
    private Double professionalTax;
    private Double otherDeductions;
    private Double grossPay;
    private Double netPay;
    private Integer totalWorkingDays;
    private Integer daysPresent;
    private Integer daysAbsent;
    private Integer daysOnLeave;
    private String pdfUrl;
    private Boolean isGenerated;
    private LocalDateTime generatedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class EmployeeInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
        private String designation;
        private String department;
    }
}
