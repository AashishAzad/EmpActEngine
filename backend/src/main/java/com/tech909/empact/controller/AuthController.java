package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ChangePasswordRequest;
import com.tech909.empact.dto.request.LoginRequest;
import com.tech909.empact.dto.request.RefreshTokenRequest;
import com.tech909.empact.dto.response.AuthResponse;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.service.AuthService;
import com.tech909.empact.service.EmployeeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Auth Controller
 *
 * Base path: /auth (full path: /api/v1/auth)
 *
 * Endpoints:
 * POST /auth/login         → login with employeeId + password
 * GET  /auth/profile       → get current user profile
 * POST /auth/refresh       → get new access token
 * POST /auth/logout        → stateless logout (client drops token)
 *
 * Design Pattern: Thin Controller — zero business logic here.
 * All logic delegated to AuthService.
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final EmployeeService employeeService;

    /** POST /auth/login */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    /** GET /auth/profile — requires valid JWT */
    @GetMapping("/profile")
    public ResponseEntity<EmployeeResponse> getProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(employeeService.getEmployeeById(userId, false));
    }

    /** POST /auth/refresh */
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refreshToken(request));
    }

    /** POST /auth/logout — stateless, client just discards the token */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() {
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }

    /** PATCH /auth/change-password — requires valid JWT (any role) */
    @PatchMapping("/change-password")
    public ResponseEntity<Map<String, String>> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ChangePasswordRequest request) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(authService.changePassword(userId, request));
    }
}