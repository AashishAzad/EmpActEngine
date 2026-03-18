package com.tech909.empact.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider();
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtSecret",
                "EmpAct909TechSecretKeyForJWTTokenGenerationEmployeeActivitySystem2026");
        ReflectionTestUtils.setField(jwtTokenProvider, "jwtExpirationMs", 60_000L);
        ReflectionTestUtils.setField(jwtTokenProvider, "refreshExpirationMs", 120_000L);
    }

    @Test
    void generateAccessToken_containsExpectedClaims() {
        UUID userId = UUID.randomUUID();

        String token = jwtTokenProvider.generateAccessToken(
                userId, "EMP001", "emp001@example.com", "ADMIN");

        assertThat(jwtTokenProvider.validateToken(token)).isTrue();
        assertThat(jwtTokenProvider.extractUserId(token)).isEqualTo(userId.toString());
        assertThat(jwtTokenProvider.extractClaim(token, "employeeId")).isEqualTo("EMP001");
        assertThat(jwtTokenProvider.extractClaim(token, "email")).isEqualTo("emp001@example.com");
        assertThat(jwtTokenProvider.extractClaim(token, "role")).isEqualTo("ADMIN");
        assertThat(jwtTokenProvider.extractClaim(token, "type")).isEqualTo("ACCESS");
        assertThat(jwtTokenProvider.isRefreshToken(token)).isFalse();
    }

    @Test
    void generateRefreshToken_marksTokenAsRefresh() {
        UUID userId = UUID.randomUUID();

        String token = jwtTokenProvider.generateRefreshToken(userId);

        assertThat(jwtTokenProvider.validateToken(token)).isTrue();
        assertThat(jwtTokenProvider.extractUserId(token)).isEqualTo(userId.toString());
        assertThat(jwtTokenProvider.extractClaim(token, "type")).isEqualTo("REFRESH");
        assertThat(jwtTokenProvider.isRefreshToken(token)).isTrue();
    }

    @Test
    void validateToken_returnsFalseForTamperedToken() {
        String token = jwtTokenProvider.generateRefreshToken(UUID.randomUUID()) + "tampered";

        assertThat(jwtTokenProvider.validateToken(token)).isFalse();
        assertThat(jwtTokenProvider.isRefreshToken(token)).isFalse();
    }
}
