package com.tech909.empact.dto.response;

import com.tech909.empact.enums.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Auth Response DTO
 *
 * Returned after successful login.
 * Contains JWT tokens + safe user info (no password).
 * Matches the LoginResponseDto shape from NestJS backend.
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private String accessToken;
    private String refreshToken;
    private UserInfo user;

    /**
     * Nested UserInfo — safe employee data embedded in login response.
     * Never includes password or sensitive internal fields.
     */
    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserInfo {
        private UUID id;
        private String employeeId;
        private String firstName;
        private String lastName;
        private String email;
        private UserRole role;
        private String designation;
        private String department;
        private String phoneNumber;
        private LocalDate dateOfJoining;
        private Integer casualLeaveBalance;
        private Integer sickLeaveBalance;
        private Integer allPurposeLeaveBalance;
        private LocalDateTime lastLogin;
    }
}
