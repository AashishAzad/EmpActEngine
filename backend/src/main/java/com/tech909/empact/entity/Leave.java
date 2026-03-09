package com.tech909.empact.entity;

import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@JmixEntity
@Entity
@Table(name = "leave_request", indexes = {
        @Index(name = "idx_leave_employee_id", columnList = "employee_id"),
        @Index(name = "idx_leave_status",      columnList = "status"),
        @Index(name = "idx_leave_dates",       columnList = "start_date, end_date")
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Leave {

    @Id
    @JmixGeneratedValue
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @Enumerated(EnumType.STRING)
    @Column(name = "leave_type", nullable = false, length = 20)
    private LeaveType leaveType;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "number_of_days")
    private Integer numberOfDays;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private LeaveStatus status;

    @Column(name = "contact_number", length = 20)
    private String contactNumber;

    @Column(name = "contact_email", length = 100)
    private String contactEmail;

    @Column(name = "remarks", length = 500)
    private String remarks;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "action_by_id")
    private User actionBy;

    @Column(name = "action_date")
    private LocalDateTime actionDate;

    @Column(name = "action_remarks", length = 500)
    private String actionRemarks;

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