package com.tech909.empact.security;

import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Custom UserDetailsService — adapted for Jmix
 *
 * Works with Jmix's User entity (which contains all our Employee fields).
 * Spring Security calls this during JWT validation on every request.
 *
 * Key difference from original:
 * - Uses UserRepository (not EmployeeRepository) — same table, Jmix's name
 * - Jmix's DatabaseUserRepository handles Jmix-internal auth
 * - This class handles our custom JWT auth path
 *
 * Design Pattern: Adapter — adapts User entity to Spring Security's UserDetails
 */
@Service("customUserDetailsService")
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    /**
     * Load user by UUID string — called from JwtAuthenticationFilter.
     * UUID comes from the JWT 'sub' claim.
     *
     * Time Complexity: O(1) — primary key lookup
     */
    @Transactional(readOnly = true)
    public UserDetails loadUserById(String userId) {
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> {
                    log.warn("User not found for ID: {}", userId);
                    return new UsernameNotFoundException("User not found: " + userId);
                });

        if (!EmployeeStatus.ACTIVE.equals(user.getStatus())) {
            log.warn("Inactive user attempted access: {}", user.getEmployeeId());
            throw new UsernameNotFoundException("User account is not active: " + user.getEmployeeId());
        }

        // Map our UserRole enum → Spring Security ROLE_ convention
        // e.g. UserRole.ADMIN → "ROLE_ADMIN"
        List<SimpleGrantedAuthority> authorities = List.of(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getId().toString())
                .password(user.getPassword())
                .authorities(authorities)
                .accountLocked(!user.isActive())
                .disabled(!user.isActive())
                .build();
    }

    /**
     * Load by employeeId (e.g. EMP001) — used during login authentication.
     * employeeId is stored in the 'username' column so this works directly.
     */
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String employeeId) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(employeeId)
                .orElseThrow(() -> new UsernameNotFoundException("Employee not found: " + employeeId));

        List<SimpleGrantedAuthority> authorities = List.of(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getId().toString())
                .password(user.getPassword())
                .authorities(authorities)
                .build();
    }
}