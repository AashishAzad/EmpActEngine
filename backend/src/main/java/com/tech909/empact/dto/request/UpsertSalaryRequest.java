package com.tech909.empact.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

/** POST /payroll/salary — Admin only */
@Getter
@Setter
public class UpsertSalaryRequest {

    @NotNull(message = "Employee ID is required")
    private UUID employeeId;

    @NotNull @Min(0)
    private Double basicPay;

    @NotNull @Min(0)
    private Double hra;

    @NotNull @Min(0)
    private Double specialAllowance;

    @Min(0)
    private Double otherAllowances = 0.0;

    @NotNull @Min(0)
    private Double pf;

    @Min(0)
    private Double professionalTax = 0.0;

    @Min(0)
    private Double otherDeductions = 0.0;
}
