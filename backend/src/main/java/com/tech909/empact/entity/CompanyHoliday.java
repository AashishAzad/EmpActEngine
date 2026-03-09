package com.tech909.empact.entity;

import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@JmixEntity
@Entity
@Table(name = "company_holiday", indexes = {
        @Index(name = "idx_holiday_date", columnList = "date", unique = true)
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class CompanyHoliday {

    @Id
    @JmixGeneratedValue
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "date", nullable = false, unique = true)
    private LocalDate date;

    @Column(name = "is_recurring")
    private Boolean isRecurring = false;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}