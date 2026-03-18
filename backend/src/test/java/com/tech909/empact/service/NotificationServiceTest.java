package com.tech909.empact.service;

import com.tech909.empact.dto.request.CreateNotificationRequest;
import com.tech909.empact.dto.response.NotificationResponse;
import com.tech909.empact.entity.Notification;
import com.tech909.empact.entity.NotificationReceipt;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.repository.NotificationReceiptRepository;
import com.tech909.empact.repository.NotificationRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private NotificationReceiptRepository receiptRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private NotificationService notificationService;

    @Test
    void createNotification_global_createsReceiptsForActiveUsersAndBroadcasts() {
        UUID creatorId = UUID.randomUUID();
        User creator = buildUser(creatorId, "ADM001");
        User userOne = buildUser(UUID.randomUUID(), "EMP001");
        User userTwo = buildUser(UUID.randomUUID(), "EMP002");

        CreateNotificationRequest request = new CreateNotificationRequest();
        request.setTitle("Policy Update");
        request.setMessage("Please read the new policy.");
        request.setType("ANNOUNCEMENT");
        request.setIsGlobal(true);
        request.setVisibleTill(LocalDateTime.now().plusDays(5));

        when(userRepository.findById(creatorId)).thenReturn(Optional.of(creator));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findByStatus(EmployeeStatus.ACTIVE)).thenReturn(List.of(userOne, userTwo));

        NotificationResponse response = notificationService.createNotification(request, creatorId);

        ArgumentCaptor<List<NotificationReceipt>> receiptCaptor = ArgumentCaptor.forClass(List.class);
        verify(receiptRepository).saveAll(receiptCaptor.capture());
        assertThat(receiptCaptor.getValue()).hasSize(2);

        verify(messagingTemplate).convertAndSend(eq("/topic/notifications"), any(NotificationResponse.class));
        assertThat(response.getTitle()).isEqualTo("Policy Update");
        assertThat(response.getIsGlobal()).isTrue();
    }

    @Test
    void createNotification_withSpecificRecipients_createsReceiptsAndPushesToUsers() {
        UUID creatorId = UUID.randomUUID();
        UUID recipientOneId = UUID.randomUUID();
        UUID recipientTwoId = UUID.randomUUID();
        User creator = buildUser(creatorId, "ADM001");
        User recipientOne = buildUser(recipientOneId, "EMP001");
        User recipientTwo = buildUser(recipientTwoId, "EMP002");

        CreateNotificationRequest request = new CreateNotificationRequest();
        request.setTitle("Meeting");
        request.setMessage("Join the sync.");
        request.setType("MEETING");
        request.setIsGlobal(false);
        request.setRecipientIds(List.of(recipientOneId, recipientTwoId));

        when(userRepository.findById(creatorId)).thenReturn(Optional.of(creator));
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findById(recipientOneId)).thenReturn(Optional.of(recipientOne));
        when(userRepository.findById(recipientTwoId)).thenReturn(Optional.of(recipientTwo));

        notificationService.createNotification(request, creatorId);

        verify(receiptRepository).saveAll(any(List.class));
        verify(messagingTemplate).convertAndSendToUser(eq(recipientOneId.toString()), eq("/queue/notifications"), any(NotificationResponse.class));
        verify(messagingTemplate).convertAndSendToUser(eq(recipientTwoId.toString()), eq("/queue/notifications"), any(NotificationResponse.class));
        verify(messagingTemplate, never()).convertAndSend(eq("/topic/notifications"), any(NotificationResponse.class));
    }

    @Test
    void markAsRead_whenUnread_updatesReceiptAndPushesUnreadCount() {
        UUID notificationId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        Notification notification = Notification.builder()
                .id(notificationId)
                .title("Reminder")
                .message("Mark attendance")
                .type("ATTENDANCE")
                .isGlobal(false)
                .build();

        NotificationReceipt receipt = NotificationReceipt.builder()
                .id(UUID.randomUUID())
                .notification(notification)
                .employee(buildUser(userId, "EMP001"))
                .isRead(false)
                .build();

        when(receiptRepository.findByNotification_IdAndEmployee_Id(notificationId, userId))
                .thenReturn(Optional.of(receipt));
        when(receiptRepository.countUnreadForEmployee(eq(userId), any(LocalDateTime.class))).thenReturn(3L);

        NotificationResponse response = notificationService.markAsRead(notificationId, userId);

        verify(receiptRepository).save(receipt);
        verify(messagingTemplate).convertAndSendToUser(eq(userId.toString()), eq("/queue/unread-count"), eq(java.util.Map.of("count", 3L)));
        assertThat(response.getIsRead()).isTrue();
        assertThat(receipt.getReadAt()).isNotNull();
    }

    @Test
    void markAsRead_whenAlreadyRead_skipsSaveAndUnreadPush() {
        UUID notificationId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        NotificationReceipt receipt = NotificationReceipt.builder()
                .id(UUID.randomUUID())
                .notification(Notification.builder()
                        .id(notificationId)
                        .title("Reminder")
                        .message("Already read")
                        .type("INFO")
                        .build())
                .employee(buildUser(userId, "EMP001"))
                .isRead(true)
                .readAt(LocalDateTime.now().minusHours(1))
                .build();

        when(receiptRepository.findByNotification_IdAndEmployee_Id(notificationId, userId))
                .thenReturn(Optional.of(receipt));

        NotificationResponse response = notificationService.markAsRead(notificationId, userId);

        verify(receiptRepository, never()).save(receipt);
        verify(messagingTemplate, never()).convertAndSendToUser(eq(userId.toString()), eq("/queue/unread-count"), any());
        assertThat(response.getIsRead()).isTrue();
    }

    private User buildUser(UUID userId, String employeeId) {
        User user = new User();
        user.setId(userId);
        user.setEmployeeId(employeeId);
        user.setFirstName("Test");
        user.setLastName("User");
        user.setStatus(EmployeeStatus.ACTIVE);
        return user;
    }
}
