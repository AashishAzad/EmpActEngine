package com.tech909.empact.dto.request;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

/** POST /payroll/generate-payslip — Admin only */
@Getter
@Setter
public class GeneratePayslipRequest {

    @NotNull(message = "Employee ID is required")
    private UUID employeeId;

    @NotNull @Min(1) @Max(12)
    private Integer month;

    @NotNull @Min(2020) @Max(2100)
    private Integer year;
}
