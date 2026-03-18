package com.tech909.empact.exception;

import com.tech909.empact.dto.request.LoginRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.core.MethodParameter;

import java.lang.reflect.Method;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
    }

    @Test
    void handleBusinessException_returnsBadRequestBody() {
        ResponseEntity<Map<String, Object>> response =
                handler.handleBusinessException(new BusinessException("Rule violated"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).containsEntry("message", "Rule violated");
        assertThat(response.getBody()).containsEntry("error", "Bad Request");
    }

    @Test
    void handleBadCredentials_returnsUnauthorizedMessage() {
        ResponseEntity<Map<String, Object>> response =
                handler.handleBadCredentials(new BadCredentialsException("bad"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).containsEntry("message", "Invalid credentials");
    }

    @Test
    void handleAccessDenied_returnsForbiddenMessage() {
        ResponseEntity<Map<String, Object>> response =
                handler.handleAccessDenied(new AccessDeniedException("denied"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(response.getBody()).containsEntry("message", "You do not have permission to access this resource");
    }

    @Test
    void handleValidationErrors_returnsFieldErrorMap() throws Exception {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new LoginRequest(), "loginRequest");
        bindingResult.addError(new FieldError("loginRequest", "employeeId", "Employee ID is required"));

        Method method = ValidationTarget.class.getDeclaredMethod("accept", LoginRequest.class);
        MethodParameter parameter = new MethodParameter(method, 0);
        MethodArgumentNotValidException exception = new MethodArgumentNotValidException(parameter, bindingResult);

        ResponseEntity<Map<String, Object>> response = handler.handleValidationErrors(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).containsEntry("message", "Request validation failed");
        assertThat((Map<String, String>) response.getBody().get("fieldErrors"))
                .containsEntry("employeeId", "Employee ID is required");
    }

    private static class ValidationTarget {
        void accept(@Valid LoginRequest request) {
        }
    }
}
