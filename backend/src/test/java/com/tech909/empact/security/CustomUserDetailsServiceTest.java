package com.tech909.empact.security;

import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomUserDetailsServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void loadUserById_returnsSpringUserForActiveEmployee() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, "EMP001", EmployeeStatus.ACTIVE, UserRole.ADMIN);
        user.setPassword("encoded-pass");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        var result = customUserDetailsService.loadUserById(userId.toString());

        assertThat(result.getUsername()).isEqualTo(userId.toString());
        assertThat(result.getPassword()).isEqualTo("encoded-pass");
        assertThat(result.getAuthorities()).extracting("authority").containsExactly("ROLE_ADMIN");
    }

    @Test
    void loadUserById_throwsWhenUserIsInactive() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, "EMP001", EmployeeStatus.INACTIVE, UserRole.EMPLOYEE);

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> customUserDetailsService.loadUserById(userId.toString()))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessage("User account is not active: EMP001");
    }

    @Test
    void loadUserByUsername_returnsSpringUserForEmployeeId() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, "EMP009", EmployeeStatus.ACTIVE, UserRole.MANAGER);
        user.setPassword("encoded-pass");

        when(userRepository.findByUsername("EMP009")).thenReturn(Optional.of(user));

        var result = customUserDetailsService.loadUserByUsername("EMP009");

        assertThat(result.getUsername()).isEqualTo(userId.toString());
        assertThat(result.getAuthorities()).extracting("authority").containsExactly("ROLE_MANAGER");
    }

    private User buildUser(UUID id, String employeeId, EmployeeStatus status, UserRole role) {
        User user = new User();
        user.setId(id);
        user.setEmployeeId(employeeId);
        user.setStatus(status);
        user.setRole(role);
        return user;
    }
}
