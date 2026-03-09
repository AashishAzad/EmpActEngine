package com.tech909.empact.service;

import com.tech909.empact.dto.request.CreateNotificationRequest;
import com.tech909.empact.dto.response.NotificationResponse;
import com.tech909.empact.entity.Notification;
import com.tech909.empact.entity.NotificationReceipt;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.NotificationReceiptRepository;
import com.tech909.empact.repository.NotificationRepository;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Notification Service
 *
 * Handles in-app notifications with real-time WebSocket delivery.
 *
 * Two delivery paths:
 * 1. REST API — creates notification + receipts in DB (persistent, offline-safe)
 * 2. WebSocket (STOMP) — pushes to connected users in real-time
 *
 * If user is offline when notification is created:
 * → They still see it in their feed via REST (DB-backed)
 * → They get unread count update when they reconnect
 *
 * Design Pattern: Observer Pattern
 * NotificationService notifies observers (WebSocket clients) when
 * new notifications are created.
 *
 * SimpMessagingTemplate — Spring's STOMP message sender
 * Replaces Socket.IO's server.to(userId).emit(...)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationReceiptRepository receiptRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Create Notification (Admin/Manager)
     *
     * Algorithm:
     * 1. Create Notification record
     * 2. Create NotificationReceipt for each recipient (global = all active users)
     * 3. Push real-time event via WebSocket to connected users
     *
     * Time Complexity: O(n) where n = number of recipients
     *
     * @param request notification data
     * @param createdById creator's UUID
     * @return created notification response
     */
    @Transactional
    public NotificationResponse createNotification(
            CreateNotificationRequest request, UUID createdById) {

        User creator = userRepository.findById(createdById)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", createdById));

        Notification notification = Notification.builder()
                .id(UUID.randomUUID())
                .title(request.getTitle())
                .isGlobal(request.getIsGlobal() != null && request.getIsGlobal())
                .visibleTill(request.getVisibleTill())
                .referenceId(request.getReferenceId())
                .referenceType(request.getReferenceType())
                .build();

        Notification saved = notificationRepository.save(notification);

        // Create receipts and push WebSocket events
        if (Boolean.TRUE.equals(request.getIsGlobal())) {
            createReceiptsForAllActiveUsers(saved);
            pushToAllUsers(saved);
        } else if (request.getRecipientIds() != null && !request.getRecipientIds().isEmpty()) {
            createReceiptsForUsers(saved, request.getRecipientIds());
            pushToSpecificUsers(saved, request.getRecipientIds());
        }

        log.info("Notification created: '{}' by {}", saved.getTitle(), creator.getEmployeeId());
        return mapToResponse(saved, false, null);
    }

    /**
     * Get Notifications for Employee (their personal feed)
     *
     * Fetches receipts with notification data, applies filters.
     *
     * @param userId        employee UUID
     * @param unreadOnly    show only unread
     * @param includeExpired include expired notifications
     * @param type          optional type filter
     */
    @Transactional(readOnly = true)
    public List<NotificationResponse> getNotificationsForEmployee(
            UUID userId, boolean unreadOnly, boolean includeExpired, String type) {

        return receiptRepository
                .findReceiptsForEmployee(userId, unreadOnly, includeExpired,
                        LocalDateTime.now(), type)
                .stream()
                .map(receipt -> mapToResponse(
                        receipt.getNotification(),
                        receipt.getIsRead(),
                        receipt.getReadAt()))
                .toList();
    }

    /**
     * Mark Notification as Read
     *
     * Updates the receipt record (isRead = true, readAt = now).
     * Then pushes updated unread count via WebSocket.
     *
     * @param notificationId notification UUID
     * @param userId         employee UUID
     */
    @Transactional
    public NotificationResponse markAsRead(UUID notificationId, UUID userId) {
        NotificationReceipt receipt = receiptRepository
                .findByNotification_IdAndEmployee_Id(notificationId, userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Notification", "id", notificationId));

        if (!receipt.getIsRead()) {
            receipt.setIsRead(true);
            receipt.setReadAt(LocalDateTime.now());
            receiptRepository.save(receipt);

            // Push updated unread count to user via WebSocket
            pushUnreadCount(userId);
        }

        return mapToResponse(receipt.getNotification(), true, receipt.getReadAt());
    }

    /**
     * Get Unread Count for employee
     * Used by WebSocket to push badge number on connect/read events.
     */
    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return receiptRepository.countUnreadForEmployee(userId, LocalDateTime.now());
    }

    /**
     * Delete Notification (Admin only)
     * Cascade deletes all receipts via JPA cascade.
     */
    @Transactional
    public Map<String, String> deleteNotification(UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Notification", "id", notificationId));

        notificationRepository.delete(notification);
        log.info("Notification deleted: {}", notificationId);
        return Map.of("message", "Notification deleted successfully");
    }

    /**
     * Create System Notification — called internally by other services
     * (scheduler, leave approval, letter completion, etc.)
     *
     * No WebSocket push here — callers handle that if needed.
     * This just persists the notification + receipts.
     *
     * @param type           notification type constant
     * @param title          notification title
     * @param message        notification message
     * @param recipientIds   list of employee UUIDs to notify
     * @param referenceId    optional linked entity ID (for deep linking)
     * @param referenceType  optional linked entity type
     */
    @Transactional
    public void createSystemNotification(
            String type, String title, String message,
            List<UUID> recipientIds,
            String referenceId, String referenceType) {

        Notification notification = Notification.builder()
                .id(UUID.randomUUID())
                .title(title)
                .message(message)
                .type(type)
                .isGlobal(false)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .build();

        Notification saved = notificationRepository.save(notification);
        createReceiptsForUsers(saved, recipientIds);

        // Also push real-time to each recipient
        pushToSpecificUsers(saved, recipientIds);

        log.info("System notification created: {} for {} recipients", type, recipientIds.size());
    }

    /** Overload without referenceId/Type for simple notifications */
    @Transactional
    public void createSystemNotification(
            String type, String title, String message, List<UUID> recipientIds) {
        createSystemNotification(type, title, message, recipientIds, null, null);
    }

    // ── WebSocket Push Methods ────────────────────────────────────────────────

    /**
     * Push notification to a specific user via STOMP WebSocket.
     *
     * Spring's SimpMessagingTemplate.convertAndSendToUser() sends to:
     * /user/{userId}/queue/notifications
     *
     * Flutter's stomp_dart_client subscribes to:
     * /user/queue/notifications
     * (Spring automatically prepends /user/{userId} for the correct session)
     */
    public void pushNotificationToUser(UUID userId, NotificationResponse notification) {
        messagingTemplate.convertAndSendToUser(
                userId.toString(),
                "/queue/notifications",
                notification
        );
        pushUnreadCount(userId);
    }

    /**
     * Push notification to all connected users.
     * Spring sends to /topic/notifications — clients subscribe to this topic.
     */
    public void pushToAllUsers(Notification notification) {
        NotificationResponse response = mapToResponse(notification, false, null);
        messagingTemplate.convertAndSend("/topic/notifications", response);
        log.debug("Broadcast notification to all users: {}", notification.getTitle());
    }

    /** Push to a specific list of users */
    public void pushToSpecificUsers(Notification notification, List<UUID> userIds) {
        NotificationResponse response = mapToResponse(notification, false, null);
        for (UUID userId : userIds) {
            messagingTemplate.convertAndSendToUser(
                    userId.toString(), "/queue/notifications", response);
        }
    }

    /** Push updated unread count badge to a user */
    public void pushUnreadCount(UUID userId) {
        long count = getUnreadCount(userId);
        messagingTemplate.convertAndSendToUser(
                userId.toString(),
                "/queue/unread-count",
                Map.of("count", count)
        );
    }

    // ── Receipt Creation Helpers ──────────────────────────────────────────────

    /** Create receipts for ALL active employees (global notification) */
    private void createReceiptsForAllActiveUsers(Notification notification) {
        List<User> activeUsers = userRepository.findByStatus(EmployeeStatus.ACTIVE);
        List<NotificationReceipt> receipts = activeUsers.stream()
                .map(user -> NotificationReceipt.builder()
                        .id(UUID.randomUUID())
                        .notification(notification)
                        .employee(user)
                        .isRead(false)
                        .build())
                .toList();
        receiptRepository.saveAll(receipts);
        log.debug("Created {} receipts for global notification", receipts.size());
    }

    /** Create receipts for specific users */
    private void createReceiptsForUsers(Notification notification, List<UUID> userIds) {
        List<NotificationReceipt> receipts = userIds.stream()
                .flatMap(userId -> userRepository.findById(userId).stream())
                .map(user -> NotificationReceipt.builder()
                        .id(UUID.randomUUID())
                        .notification(notification)
                        .employee(user)
                        .isRead(false)
                        .build())
                .toList();
        receiptRepository.saveAll(receipts);
    }

    // ── DTO Mapper ────────────────────────────────────────────────────────────

    private NotificationResponse mapToResponse(
            Notification n, boolean isRead, LocalDateTime readAt) {

        NotificationResponse.CreatorInfo creatorInfo = null;
        if (n.getCreatedBy() != null) {
            creatorInfo = NotificationResponse.CreatorInfo.builder()
                    .employeeId(n.getCreatedBy().getEmployeeId())
                    .firstName(n.getCreatedBy().getFirstName())
                    .lastName(n.getCreatedBy().getLastName())
                    .build();
        }

        return NotificationResponse.builder()
                .id(n.getId())
                .title(n.getTitle())
                .message(n.getMessage())
                .type(n.getType())
                .isGlobal(n.getIsGlobal())
                .visibleTill(n.getVisibleTill())
                .referenceId(n.getReferenceId())
                .referenceType(n.getReferenceType())
                .createdBy(creatorInfo)
                .createdAt(n.getCreatedAt())
                .isRead(isRead)
                .readAt(readAt)
                .build();
    }
}