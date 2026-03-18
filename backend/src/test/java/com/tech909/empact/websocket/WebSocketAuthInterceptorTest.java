package com.tech909.empact.websocket;

import com.tech909.empact.security.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;

import java.security.Principal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WebSocketAuthInterceptorTest {

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private MessageChannel channel;

    @InjectMocks
    private WebSocketAuthInterceptor webSocketAuthInterceptor;

    @Test
    void preSend_onValidConnectToken_setsAuthenticatedUser() {
        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
        accessor.setNativeHeader("Authorization", "Bearer valid-token");
        accessor.setLeaveMutable(true);
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        when(tokenProvider.validateToken("valid-token")).thenReturn(true);
        when(tokenProvider.extractUserId("valid-token")).thenReturn("user-1");
        when(tokenProvider.extractClaim("valid-token", "role")).thenReturn("ADMIN");

        Message<?> result = webSocketAuthInterceptor.preSend(message, channel);
        StompHeaderAccessor resultAccessor =
                org.springframework.messaging.support.MessageHeaderAccessor.getAccessor(result, StompHeaderAccessor.class);
        Principal principal = resultAccessor.getUser();

        assertThat(principal).isNotNull();
        assertThat(principal.getName()).isEqualTo("user-1");
    }

    @Test
    void preSend_onInvalidToken_leavesUserUnset() {
        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
        accessor.setNativeHeader("Authorization", "Bearer bad-token");
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        when(tokenProvider.validateToken("bad-token")).thenReturn(false);

        Message<?> result = webSocketAuthInterceptor.preSend(message, channel);

        assertThat(StompHeaderAccessor.wrap(result).getUser()).isNull();
    }

    @Test
    void preSend_onNonConnectCommand_skipsTokenValidation() {
        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.SEND);
        accessor.setNativeHeader("Authorization", "Bearer token");
        Message<byte[]> message = MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());

        Message<?> result = webSocketAuthInterceptor.preSend(message, channel);

        assertThat(StompHeaderAccessor.wrap(result).getUser()).isNull();
        verifyNoInteractions(tokenProvider);
    }
}
