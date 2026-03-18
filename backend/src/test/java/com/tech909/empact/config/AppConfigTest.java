package com.tech909.empact.config;

import com.tech909.empact.websocket.WebSocketAuthInterceptor;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.config.ChannelRegistration;

import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AppConfigTest {

    @Mock
    private WebSocketAuthInterceptor webSocketAuthInterceptor;

    @Mock
    private ChannelRegistration channelRegistration;

    @InjectMocks
    private AppConfig appConfig;

    @Test
    void configureClientInboundChannel_registersWebSocketInterceptor() {
        appConfig.configureClientInboundChannel(channelRegistration);

        verify(channelRegistration).interceptors(webSocketAuthInterceptor);
    }
}
