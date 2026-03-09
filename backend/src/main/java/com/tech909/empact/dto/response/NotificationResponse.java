package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class NotificationResponse {
    private UUID id;
    private String title;
    private String message;
    private String type;
    private Boolean isGlobal;
    private LocalDateTime visibleTill;
    private String referenceId;
    private String referenceType;
    private CreatorInfo createdBy;
    private LocalDateTime createdAt;
    private Boolean isRead;
    private LocalDateTime readAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class CreatorInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
    }
}
