package com.tech909.empact.service;

import com.tech909.empact.dto.request.LoginRequest;
import com.tech909.empact.dto.request.RefreshTokenRequest;
import com.tech909.empact.dto.response.AuthResponse;
import com.tech909.empact.entity.User;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.UserRepository;
import com.tech909.empact.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationContext;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final JwtTokenProvider tokenProvider;

    /**
     * ApplicationContext used to lazily retrieve AuthenticationManager.
     *
     * We CANNOT inject AuthenticationManager directly here because that creates
     * a circular bean dependency: SecurityConfig → AuthService → AuthenticationManager
     * → SecurityConfig. The lazy lookup via ApplicationContext breaks the cycle.
     *
     * Additionally, injecting it at construction time would get OUR manager,
     * not Jmix's fully-assembled one (which includes SystemAuthenticationProvider).
     * Lazy lookup ensures we get the final, fully-wired manager at runtime.
     */
    private final ApplicationContext applicationContext;

    private AuthenticationManager getAuthenticationManager() {
        return applicationContext.getBean(AuthenticationManager.class);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt for employeeId: {}", request.getEmployeeId());

        Authentication authentication = getAuthenticationManager().authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmployeeId(),
                        request.getPassword()
                )
        );

        // authentication.getName() returns the username (e.g. "EMP001"), NOT a UUID.
        // Look up user by employeeId instead of trying to parse the name as UUID.
        String employeeId = authentication.getName();
        User user = userRepository.findByEmployeeId(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "employeeId", employeeId));

        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        String accessToken = tokenProvider.generateAccessToken(
                user.getId(),
                user.getEmployeeId(),
                user.getEmail(),
                user.getRole().name()
        );
        String refreshToken = tokenProvider.generateRefreshToken(user.getId());

        log.info("Login successful for: {}", user.getEmployeeId());
        return buildAuthResponse(user, accessToken, refreshToken);
    }

    @Transactional(readOnly = true)
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();

        if (!tokenProvider.validateToken(refreshToken)) {
            throw new BusinessException("Invalid or expired refresh token");
        }
        if (!tokenProvider.isRefreshToken(refreshToken)) {
            throw new BusinessException("Provided token is not a refresh token");
        }

        String userId = tokenProvider.extractUserId(refreshToken);
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        String newAccessToken = tokenProvider.generateAccessToken(
                user.getId(),
                user.getEmployeeId(),
                user.getEmail(),
                user.getRole().name()
        );

        log.info("Token refreshed for: {}", user.getEmployeeId());
        return buildAuthResponse(user, newAccessToken, refreshToken);
    }

    @Transactional(readOnly = true)
    public User getProfile(String userId) {
        return userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
    }

    private AuthResponse buildAuthResponse(User user, String accessToken, String refreshToken) {
        AuthResponse.UserInfo userInfo = AuthResponse.UserInfo.builder()
                .id(user.getId())
                .employeeId(user.getEmployeeId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole())
                .designation(user.getDesignation())
                .department(user.getDepartment())
                .phoneNumber(user.getPhoneNumber())
                .dateOfJoining(user.getDateOfJoining())
                .casualLeaveBalance(user.getCasualLeaveBalance())
                .sickLeaveBalance(user.getSickLeaveBalance())
                .allPurposeLeaveBalance(user.getAllPurposeLeaveBalance())
                .lastLogin(user.getLastLogin())
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .user(userInfo)
                .build();
    }
}