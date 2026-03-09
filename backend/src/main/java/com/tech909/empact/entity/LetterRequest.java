package com.tech909.empact.entity;

import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@JmixEntity
@Entity
@Table(name = "letter_request", indexes = {
        @Index(name = "idx_letter_employee_id", columnList = "employee_id"),
        @Index(name = "idx_letter_status",      columnList = "status")
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class LetterRequest {

    @Id
    @JmixGeneratedValue
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @Enumerated(EnumType.STRING)
    @Column(name = "letter_type", nullable = false, length = 30)
    private LetterType letterType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private LetterRequestStatus status;

    @Column(name = "remarks", length = 500)
    private String remarks;

    @Column(name = "file_url", length = 500)
    private String fileUrl;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}