package com.tech909.empact.controller;

import com.tech909.empact.dto.request.CreateNotificationRequest;
import com.tech909.empact.dto.response.NotificationResponse;
import com.tech909.empact.service.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Notification Controller
 * Base path: /notifications (full path: /api/v1/notifications)
 */
@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /** POST /notifications — Admin/Manager only */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<NotificationResponse> createNotification(
            @Valid @RequestBody CreateNotificationRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID createdById = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(notificationService.createNotification(request, createdById));
    }

    /**
     * GET /notifications?unreadOnly=false&includeExpired=false&type=
     * Returns current user's notification feed
     */
    @GetMapping
    public ResponseEntity<List<NotificationResponse>> getMyNotifications(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(defaultValue = "false") boolean unreadOnly,
            @RequestParam(defaultValue = "false") boolean includeExpired,
            @RequestParam(required = false) String type) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(
                notificationService.getNotificationsForEmployee(
                        userId, unreadOnly, includeExpired, type));
    }

    /** GET /notifications/unread-count */
    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(
                Map.of("count", notificationService.getUnreadCount(userId)));
    }

    /** PATCH /notifications/{id}/read */
    @PatchMapping("/{id}/read")
    public ResponseEntity<NotificationResponse> markAsRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(notificationService.markAsRead(id, userId));
    }

    /** DELETE /notifications/{id} — Admin only */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteNotification(@PathVariable UUID id) {
        return ResponseEntity.ok(notificationService.deleteNotification(id));
    }
}
