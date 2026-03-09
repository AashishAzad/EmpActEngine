package com.tech909.empact.websocket;

import com.tech909.empact.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * WebSocket Authentication Interceptor
 *
 * Validates JWT on WebSocket CONNECT frame.
 * This is the WebSocket equivalent of JwtAuthenticationFilter.
 *
 * Flow:
 * Flutter sends STOMP CONNECT with header:
 *   Authorization: Bearer <token>
 *
 * This interceptor:
 * 1. Intercepts the CONNECT message
 * 2. Extracts and validates the JWT
 * 3. Sets the authenticated user in the STOMP session
 * 4. Spring then uses this for /user/{userId} routing
 *
 * Design Pattern: Interceptor Pattern (Chain of Responsibility)
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtTokenProvider tokenProvider;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        // Only validate on initial connection
        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {

            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);

                if (tokenProvider.validateToken(token)) {
                    String userId   = tokenProvider.extractUserId(token);
                    String role     = tokenProvider.extractClaim(token, "role");

                    // Set user in STOMP session — enables /user/{userId} routing
                    UsernamePasswordAuthenticationToken auth =
                            new UsernamePasswordAuthenticationToken(
                                    userId,
                                    null,
                                    List.of(new SimpleGrantedAuthority("ROLE_" + role))
                            );

                    accessor.setUser(auth);
                    log.debug("WebSocket authenticated: userId={}", userId);
                } else {
                    log.warn("WebSocket connection rejected: invalid token");
                }
            } else {
                log.warn("WebSocket connection rejected: no Authorization header");
            }
        }

        return message;
    }
}
