package com.tech909.empact.config;

import com.tech909.empact.websocket.WebSocketAuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * App Config
 *
 * Registers the WebSocketAuthInterceptor into the inbound channel
 * so JWT is validated on every WebSocket CONNECT frame.
 *
 * Kept separate from WebSocketConfig intentionally —
 * Single Responsibility Principle: WebSocketConfig handles routing/broker,
 * AppConfig handles cross-cutting concerns (auth interceptor).
 */
@Configuration
@RequiredArgsConstructor
public class AppConfig implements WebSocketMessageBrokerConfigurer {

    private final WebSocketAuthInterceptor webSocketAuthInterceptor;

    /**
     * Register our JWT interceptor on the inbound message channel.
     * Every message coming FROM the client passes through this interceptor.
     * On CONNECT: validates JWT and sets user principal.
     */
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(webSocketAuthInterceptor);
    }
}
