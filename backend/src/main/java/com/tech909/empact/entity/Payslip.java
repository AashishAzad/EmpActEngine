package com.tech909.empact.entity;

import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@JmixEntity
@Entity
@Table(name = "payslip", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"employee_id", "month", "year"})
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Payslip {

    @Id
    @JmixGeneratedValue
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @Column(name = "month", nullable = false)
    private Integer month;

    @Column(name = "year", nullable = false)
    private Integer year;

    @Column(name = "basic_pay")
    private Double basicPay;

    @Column(name = "hra")
    private Double hra;

    @Column(name = "special_allowance")
    private Double specialAllowance;

    @Column(name = "other_allowances")
    private Double otherAllowances;

    @Column(name = "pf")
    private Double pf;

    @Column(name = "professional_tax")
    private Double professionalTax;

    @Column(name = "other_deductions")
    private Double otherDeductions;

    @Column(name = "gross_pay")
    private Double grossPay;

    @Column(name = "net_pay")
    private Double netPay;

    @Column(name = "total_working_days")
    private Integer totalWorkingDays;

    @Column(name = "days_present")
    private Integer daysPresent;

    @Column(name = "days_absent")
    private Integer daysAbsent;

    @Column(name = "days_on_leave")
    private Integer daysOnLeave;

    @Column(name = "pdf_url", length = 500)
    private String pdfUrl;

    @Column(name = "is_generated")
    private Boolean isGenerated;

    @Column(name = "generated_at")
    private LocalDateTime generatedAt;

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