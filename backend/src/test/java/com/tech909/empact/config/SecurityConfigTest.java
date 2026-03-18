package com.tech909.empact.config;

import com.tech909.empact.security.CustomUserDetailsService;
import com.tech909.empact.security.JwtAuthenticationFilter;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class SecurityConfigTest {

    @Mock
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Mock
    private CustomUserDetailsService userDetailsService;

    @InjectMocks
    private SecurityConfig securityConfig;

    @Test
    void authenticationProvider_returnsDaoProviderUsingConfiguredDependencies() {
        AuthenticationProvider provider = securityConfig.authenticationProvider();

        assertThat(provider).isInstanceOf(DaoAuthenticationProvider.class);
        DaoAuthenticationProvider daoProvider = (DaoAuthenticationProvider) provider;
        assertThat(daoProvider).isNotNull();
    }

    @Test
    void passwordEncoder_createsWorkingBcryptEncoder() {
        PasswordEncoder encoder = securityConfig.passwordEncoder();
        String encoded = encoder.encode("secret123");

        assertThat(encoded).isNotEqualTo("secret123");
        assertThat(encoder.matches("secret123", encoded)).isTrue();
    }
}
