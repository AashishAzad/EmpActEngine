package com.tech909.empact.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** POST /notifications — Admin/Manager only */
@Getter
@Setter
public class CreateNotificationRequest {

    @NotBlank(message = "Title is required")
    private String title;

    @NotBlank(message = "Message is required")
    private String message;

    @NotBlank(message = "Type is required")
    private String type; // ANNOUNCEMENT, LEAVE_REQUEST, etc.

    private Boolean isGlobal = false;

    /** If not global, specify recipient employee UUIDs */
    private List<UUID> recipientIds;

    private LocalDateTime visibleTill;

    private String referenceId;
    private String referenceType;
}
