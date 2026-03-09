package com.tech909.empact.entity;

import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@JmixEntity
@Entity
@Table(name = "salary")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Salary {

    @Id
    @JmixGeneratedValue
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", unique = true, nullable = false)
    private User employee;

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

    @Column(name = "net_pay")
    private Double netPay;

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

    public double calculateGrossPay() {
        return nvl(basicPay) + nvl(hra) + nvl(specialAllowance) + nvl(otherAllowances);
    }

    public double calculateTotalDeductions() {
        return nvl(pf) + nvl(professionalTax) + nvl(otherDeductions);
    }

    private double nvl(Double value) {
        return value != null ? value : 0.0;
    }
}