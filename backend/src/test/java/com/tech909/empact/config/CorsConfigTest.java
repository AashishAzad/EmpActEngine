package com.tech909.empact.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.filter.CorsFilter;

import static org.assertj.core.api.Assertions.assertThat;

class CorsConfigTest {

    @Test
    void corsFilter_allowsConfiguredMethodsAndOrigins() throws Exception {
        CorsConfig corsConfig = new CorsConfig();
        ReflectionTestUtils.setField(corsConfig, "allowedOriginsRaw", "*");

        CorsFilter filter = corsConfig.corsFilter();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setMethod("OPTIONS");
        request.setRequestURI("/api/v1/employees");
        request.addHeader("Origin", "http://localhost:3000");
        request.addHeader("Access-Control-Request-Method", "POST");
        request.addHeader("Access-Control-Request-Headers", "Authorization");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, (req, res) -> {});

        assertThat(response.getHeader("Access-Control-Allow-Origin")).isEqualTo("http://localhost:3000");
        assertThat(response.getHeader("Access-Control-Allow-Methods")).contains("POST");
        assertThat(response.getHeader("Access-Control-Allow-Credentials")).isEqualTo("true");
    }
}
