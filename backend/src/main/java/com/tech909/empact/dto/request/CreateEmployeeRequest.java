package com.tech909.empact.dto.request;

import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/**
 * Create Employee Request DTO
 * POST /employees — Admin only
 */
@Getter
@Setter
public class CreateEmployeeRequest {

    @NotBlank(message = "Employee ID is required")
    @Size(max = 20, message = "Employee ID must not exceed 20 characters")
    private String employeeId;

    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    @Email(message = "Invalid email format")
    @NotBlank(message = "Email is required")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    private UserRole role = UserRole.EMPLOYEE;
    private EmployeeStatus status = EmployeeStatus.ACTIVE;
    private String designation;
    private String department;
    private LocalDate dateOfJoining;
    private String qualification;
    private String phoneNumber;
    private String address;
    private String emergencyContact;

    @Min(0) @Max(30)
    private Integer casualLeaveBalance = 8;

    @Min(0) @Max(30)
    private Integer sickLeaveBalance = 8;

    @Min(0) @Max(30)
    private Integer allPurposeLeaveBalance = 10;
}
