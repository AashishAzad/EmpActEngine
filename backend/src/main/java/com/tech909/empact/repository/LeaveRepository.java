package com.tech909.empact.repository;

import com.tech909.empact.entity.Leave;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import com.tech909.empact.enums.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Leave Repository
 *
 * Supports filtered, paginated queries for the leave management workflow.
 * Manager RBAC filter: only shows EMPLOYEE leaves to managers.
 */
@Repository
public interface LeaveRepository extends JpaRepository<Leave, UUID> {

    /** All pending leaves — admin sees all, manager sees only EMPLOYEE leaves */
    @Query("""
            SELECT l FROM Leave l
            WHERE l.status = 'PENDING'
            AND (:role IS NULL OR l.employee.role = :role)
            ORDER BY l.createdAt DESC
            """)
    List<Leave> findPendingLeaves(@Param("role") UserRole employeeRoleFilter);

    /** Paginated filtered leaves for GET /leaves */
    @Query("""
            SELECT l FROM Leave l
            WHERE (:employeeId IS NULL OR l.employee.id = :employeeId)
            AND (:status IS NULL OR l.status = :status)
            AND (:leaveType IS NULL OR l.leaveType = :leaveType)
            AND (:startDate IS NULL OR l.startDate >= :startDate)
            AND (:endDate IS NULL OR l.endDate <= :endDate)
            ORDER BY l.createdAt DESC
            """)
    Page<Leave> findLeavesFiltered(
            @Param("employeeId") UUID employeeId,
            @Param("status") LeaveStatus status,
            @Param("leaveType") LeaveType leaveType,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            Pageable pageable
    );

    /** Approved leaves in year — used to calculate used balance */
    List<Leave> findByEmployee_IdAndStatusAndStartDateBetween(
            UUID employeeId, LeaveStatus status, LocalDate startDate, LocalDate endDate);

    long countByStatus(LeaveStatus status);
    long countByLeaveTypeAndStatus(LeaveType leaveType, LeaveStatus status);
    long countByStartDateBetween(LocalDate startDate, LocalDate endDate);
}
