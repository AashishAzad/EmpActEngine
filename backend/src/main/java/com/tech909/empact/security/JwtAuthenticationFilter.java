package com.tech909.empact.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT Authentication Filter
 *
 * Intercepts every HTTP request and validates the JWT token.
 * If valid, sets the authenticated user in Spring Security's context.
 *
 * Execution Flow:
 * HTTP Request → JwtAuthenticationFilter → SecurityContext → Controller
 *
 * Algorithm (per request):
 * 1. Extract JWT from "Authorization: Bearer <token>" header
 * 2. Validate token (signature + expiry)
 * 3. Extract userId from token
 * 4. Load user from DB via CustomUserDetailsService
 * 5. Set authentication in SecurityContextHolder
 *
 * Design Pattern: Chain of Responsibility (Filter Chain)
 * Extends OncePerRequestFilter — guaranteed to run exactly once per request
 *
 * Time Complexity: O(1) — indexed DB lookup by UUID
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final CustomUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            // Step 1: Extract JWT from Authorization header
            String jwt = extractJwtFromRequest(request);

            // Step 2: Validate token
            if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {

                // Step 3: Extract user ID from token claims
                String userId = tokenProvider.extractUserId(jwt);

                // Step 4: Load full user details from DB (validates user still ACTIVE)
                UserDetails userDetails = userDetailsService.loadUserById(userId);

                // Step 5: Create authentication object with role-based authorities
                // UsernamePasswordAuthenticationToken is Spring's standard auth holder
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null, // credentials (not needed after auth)
                                userDetails.getAuthorities() // ROLE_ADMIN, ROLE_MANAGER, etc.
                        );

                authentication.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                // Step 6: Store in SecurityContext — controllers can access via SecurityContextHolder
                SecurityContextHolder.getContext().setAuthentication(authentication);

                log.debug("Authenticated user: {}, URI: {}", userId, request.getRequestURI());
            }

        } catch (Exception ex) {
            // Don't throw — just log and continue. Spring Security will reject unauthorized requests.
            log.debug("Could not authenticate user: {}", ex.getMessage());
        }

        // Continue filter chain regardless
        filterChain.doFilter(request, response);
    }

    /**
     * Extract JWT token from HTTP request header.
     *
     * Expects: Authorization: Bearer eyJhbGc...
     *
     * @param request HTTP request
     * @return JWT string, or null if not present
     */
    private String extractJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");

        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7); // Remove "Bearer " prefix (7 chars)
        }

        return null;
    }
}
