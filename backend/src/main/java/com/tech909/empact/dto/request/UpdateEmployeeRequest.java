package com.tech909.empact.dto.request;

import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/**
 * Update Employee Request DTO
 * PATCH /employees/:id — Admin only
 * All fields optional — only non-null fields are updated.
 */
@Getter
@Setter
public class UpdateEmployeeRequest {

    private String employeeId;
    private String firstName;
    private String lastName;

    @Email(message = "Invalid email format")
    private String email;

    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password; // Will be re-hashed if provided

    private UserRole role;
    private EmployeeStatus status;
    private String designation;
    private String department;
    private LocalDate dateOfJoining;
    private String qualification;
    private String phoneNumber;
    private String address;
    private String emergencyContact;

    @Min(0) @Max(30)
    private Integer casualLeaveBalance;

    @Min(0) @Max(30)
    private Integer sickLeaveBalance;

    @Min(0) @Max(30)
    private Integer allPurposeLeaveBalance;
}