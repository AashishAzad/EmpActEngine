package com.tech909.empact.service;

import com.tech909.empact.dto.request.ChangePasswordRequest;
import com.tech909.empact.dto.request.LoginRequest;
import com.tech909.empact.dto.request.RefreshTokenRequest;
import com.tech909.empact.dto.response.AuthResponse;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.repository.UserRepository;
import com.tech909.empact.security.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationContext;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private ApplicationContext applicationContext;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private AuthService authService;

    @Test
    void login_updatesLastLoginAndReturnsTokens() {
        LoginRequest request = new LoginRequest();
        request.setEmployeeId("EMP001");
        request.setPassword("secret123");

        User user = buildUser();
        user.setLastLogin(null);

        when(applicationContext.getBean(AuthenticationManager.class)).thenReturn(authenticationManager);
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(authentication);
        when(authentication.getName()).thenReturn("EMP001");
        when(userRepository.findByEmployeeId("EMP001")).thenReturn(Optional.of(user));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(tokenProvider.generateAccessToken(user.getId(), user.getEmployeeId(), user.getEmail(), user.getRole().name()))
                .thenReturn("access-token");
        when(tokenProvider.generateRefreshToken(user.getId())).thenReturn("refresh-token");

        AuthResponse response = authService.login(request);

        assertThat(response.getAccessToken()).isEqualTo("access-token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh-token");
        assertThat(response.getUser().getEmployeeId()).isEqualTo("EMP001");

        ArgumentCaptor<User> savedUserCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(savedUserCaptor.capture());
        assertThat(savedUserCaptor.getValue().getLastLogin()).isNotNull();
    }

    @Test
    void refreshToken_withInvalidToken_throwsBusinessException() {
        RefreshTokenRequest request = new RefreshTokenRequest();
        request.setRefreshToken("bad-token");

        when(tokenProvider.validateToken("bad-token")).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshToken(request))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Invalid or expired refresh token");
    }

    @Test
    void changePassword_withMismatchedPasswords_throwsBusinessException() {
        ChangePasswordRequest request = new ChangePasswordRequest();
        request.setCurrentPassword("old-pass");
        request.setNewPassword("new-pass");
        request.setConfirmPassword("different-pass");

        assertThatThrownBy(() -> authService.changePassword(UUID.randomUUID(), request))
                .isInstanceOf(BusinessException.class)
                .hasMessage("New password and confirm password do not match");
    }

    @Test
    void changePassword_withValidRequest_encodesAndSavesPassword() {
        UUID userId = UUID.randomUUID();
        ChangePasswordRequest request = new ChangePasswordRequest();
        request.setCurrentPassword("old-pass");
        request.setNewPassword("new-pass");
        request.setConfirmPassword("new-pass");

        User user = buildUser();
        user.setPassword("encoded-old-pass");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("old-pass", "encoded-old-pass")).thenReturn(true);
        when(passwordEncoder.encode("new-pass")).thenReturn("encoded-new-pass");

        var result = authService.changePassword(userId, request);

        assertThat(result).containsEntry("message", "Password changed successfully");
        assertThat(user.getPassword()).isEqualTo("encoded-new-pass");
        verify(userRepository).save(user);
    }

    private User buildUser() {
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setEmployeeId("EMP001");
        user.setFirstName("Aashi");
        user.setLastName("Sharma");
        user.setEmail("aashi@example.com");
        user.setRole(UserRole.EMPLOYEE);
        user.setDesignation("Engineer");
        user.setDepartment("Tech");
        user.setPhoneNumber("9999999999");
        user.setDateOfJoining(LocalDate.of(2024, 1, 10));
        user.setCasualLeaveBalance(8);
        user.setSickLeaveBalance(8);
        user.setAllPurposeLeaveBalance(10);
        user.setLastLogin(LocalDateTime.of(2025, 1, 1, 10, 0));
        return user;
    }
}
