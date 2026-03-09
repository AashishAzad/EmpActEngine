package com.tech909.empact.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/**
 * Login Request DTO
 *
 * Incoming payload for POST /auth/login
 * Validated automatically by @Valid in the controller.
 */
@Getter
@Setter
public class LoginRequest {

    @NotBlank(message = "Employee ID is required")
    private String employeeId; // e.g. EMP001, MGR001, ADM001

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;
}
