package com.tech909.empact.repository;

import com.tech909.empact.entity.Payslip;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Payslip Repository
 * Unique constraint: one payslip per employee per month per year.
 */
@Repository
public interface PayslipRepository extends JpaRepository<Payslip, UUID> {

    Optional<Payslip> findByEmployee_IdAndMonthAndYear(UUID employeeId, int month, int year);

    boolean existsByEmployee_IdAndMonthAndYear(UUID employeeId, int month, int year);

    /** Recent payslips for employee — ordered by year DESC, month DESC */
    List<Payslip> findTop3ByEmployee_IdOrderByYearDescMonthDesc(UUID employeeId);

    /** Paginated payslips with optional filters */
    @Query("""
            SELECT p FROM Payslip p
            WHERE (:employeeId IS NULL OR p.employee.id = :employeeId)
            AND (:month IS NULL OR p.month = :month)
            AND (:year IS NULL OR p.year = :year)
            ORDER BY p.year DESC, p.month DESC
            """)
    Page<Payslip> findPayslipsFiltered(
            @Param("employeeId") UUID employeeId,
            @Param("month") Integer month,
            @Param("year") Integer year,
            Pageable pageable
    );

    long countByMonthAndYear(int month, int year);
}
