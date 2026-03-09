package com.tech909.empact.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * WebSocket Configuration (STOMP)
 *
 * Replaces Socket.IO from the NestJS backend.
 * Spring's WebSocket + STOMP is more production-grade and
 * has native Java/Spring integration — no external library needed.
 *
 * How it works:
 * 1. Flutter connects to ws://localhost:8080/api/v1/ws
 * 2. Server validates JWT during handshake (see WebSocketAuthInterceptor)
 * 3. Server publishes to /topic/user/{userId} for targeted notifications
 * 4. Flutter subscribes to /user/queue/notifications for personal feed
 *
 * STOMP Protocol:
 * - Like HTTP but for WebSocket — has headers, destinations, etc.
 * - Much more structured than raw Socket.IO events
 *
 * Flutter package to use: stomp_dart_client
 * (replace socket_io_client with stomp_dart_client in pubspec.yaml)
 *
 * Flutter connection example:
 * StompClient client = StompClient(
 *   config: StompConfig(
 *     url: 'ws://192.168.x.x:8080/api/v1/ws',
 *     onConnect: onConnect,
 *     webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
 *   ),
 * );
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /**
     * Configure the message broker.
     *
     * /topic  → broadcast (one-to-many, e.g. global announcements)
     * /queue  → personal (one-to-one, e.g. targeted notifications)
     * /app    → prefix for client→server messages (not used much here)
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Enable simple in-memory broker for these destinations
        registry.enableSimpleBroker("/topic", "/queue");

        // Prefix for messages FROM client TO server
        registry.setApplicationDestinationPrefixes("/app");

        // Prefix for user-specific messages (Spring adds /user/{userId} automatically)
        registry.setUserDestinationPrefix("/user");
    }

    /**
     * Register the WebSocket endpoint.
     * Flutter connects to: ws://localhost:8080/api/v1/ws
     *
     * withSockJS() adds SockJS fallback for environments
     * that don't support native WebSocket (not needed for Flutter,
     * but good to keep for browser-based admin tools).
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS(); // fallback for non-WS environments

        // Also register without SockJS for native WebSocket clients (Flutter)
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }
}
