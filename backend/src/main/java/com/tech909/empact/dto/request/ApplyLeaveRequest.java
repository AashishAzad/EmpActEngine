package com.tech909.empact.dto.request;

import com.tech909.empact.enums.LeaveType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/** POST /leaves */
@Getter
@Setter
public class ApplyLeaveRequest {

    @NotNull(message = "Leave type is required")
    private LeaveType leaveType;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    @NotBlank(message = "Contact number is required")
    private String contactNumber;

    @Email(message = "Invalid contact email")
    @NotBlank(message = "Contact email is required")
    private String contactEmail;

    private String remarks;
}