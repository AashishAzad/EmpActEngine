package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ChangePasswordRequest;
import com.tech909.empact.dto.request.LoginRequest;
import com.tech909.empact.dto.request.RefreshTokenRequest;
import com.tech909.empact.dto.response.AuthResponse;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.service.AuthService;
import com.tech909.empact.service.EmployeeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.User;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private AuthService authService;

    @Mock
    private EmployeeService employeeService;

    @InjectMocks
    private AuthController authController;

    @Test
    void login_returnsOkWithAuthResponse() {
        LoginRequest request = new LoginRequest();
        request.setEmployeeId("EMP001");
        request.setPassword("secret123");

        AuthResponse response = AuthResponse.builder().accessToken("access").refreshToken("refresh").build();
        when(authService.login(request)).thenReturn(response);

        var result = authController.login(request);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getProfile_usesAuthenticatedUserId() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        EmployeeResponse response = EmployeeResponse.builder().id(userId).employeeId("EMP001").build();
        when(employeeService.getEmployeeById(userId, false)).thenReturn(response);

        var result = authController.getProfile(principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void refreshToken_delegatesToAuthService() {
        RefreshTokenRequest request = new RefreshTokenRequest();
        request.setRefreshToken("refresh-token");
        AuthResponse response = AuthResponse.builder().accessToken("new-access").refreshToken("refresh-token").build();
        when(authService.refreshToken(request)).thenReturn(response);

        var result = authController.refreshToken(request);

        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void changePassword_returnsServiceMessage() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        ChangePasswordRequest request = new ChangePasswordRequest();
        request.setCurrentPassword("old-pass");
        request.setNewPassword("new-pass");
        request.setConfirmPassword("new-pass");

        when(authService.changePassword(userId, request)).thenReturn(Map.of("message", "Password changed successfully"));

        var result = authController.changePassword(principal, request);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).containsEntry("message", "Password changed successfully");
        verify(authService).changePassword(userId, request);
    }
}
