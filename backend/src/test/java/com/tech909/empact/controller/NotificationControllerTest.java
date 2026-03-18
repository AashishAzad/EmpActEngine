package com.tech909.empact.controller;

import com.tech909.empact.dto.request.CreateNotificationRequest;
import com.tech909.empact.dto.response.NotificationResponse;
import com.tech909.empact.service.NotificationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.User;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationControllerTest {

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private NotificationController notificationController;

    @Test
    void createNotification_returnsCreatedResponse() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        CreateNotificationRequest request = new CreateNotificationRequest();
        request.setTitle("Announcement");
        request.setMessage("Please join");
        request.setType("GENERAL");

        NotificationResponse response = NotificationResponse.builder().title("Announcement").build();
        when(notificationService.createNotification(request, userId)).thenReturn(response);

        var result = notificationController.createNotification(request, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getUnreadCount_returnsWrappedCount() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        when(notificationService.getUnreadCount(userId)).thenReturn(5L);

        var result = notificationController.getUnreadCount(principal);

        assertThat(result.getBody()).containsEntry("count", 5L);
    }

    @Test
    void markAsRead_usesAuthenticatedUserId() {
        UUID notificationId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        NotificationResponse response = NotificationResponse.builder().id(notificationId).isRead(true).build();
        when(notificationService.markAsRead(notificationId, userId)).thenReturn(response);

        var result = notificationController.markAsRead(notificationId, principal);

        assertThat(result.getBody()).isEqualTo(response);
        verify(notificationService).markAsRead(notificationId, userId);
    }
}
