package com.tech909.empact.repository;

import com.tech909.empact.entity.NotificationReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * NotificationReceipt Repository
 *
 * The key table for per-employee notification feed + read/unread tracking.
 */
@Repository
public interface NotificationReceiptRepository extends JpaRepository<NotificationReceipt, UUID> {

    Optional<NotificationReceipt> findByNotification_IdAndEmployee_Id(
            UUID notificationId, UUID employeeId);

    /**
     * Get all notification receipts for an employee, with optional filters.
     * Filters out expired notifications unless includeExpired = true.
     */
    @Query("""
            SELECT r FROM NotificationReceipt r
            JOIN FETCH r.notification n
            WHERE r.employee.id = :employeeId
            AND (:unreadOnly = false OR r.isRead = false)
            AND (:includeExpired = true OR n.visibleTill IS NULL OR n.visibleTill > :now)
            AND (:type IS NULL OR n.type = :type)
            ORDER BY r.createdAt DESC
            """)
    List<NotificationReceipt> findReceiptsForEmployee(
            @Param("employeeId") UUID employeeId,
            @Param("unreadOnly") boolean unreadOnly,
            @Param("includeExpired") boolean includeExpired,
            @Param("now") LocalDateTime now,
            @Param("type") String type
    );

    /** Unread count — used by WebSocket to push badge count */
    @Query("""
            SELECT COUNT(r) FROM NotificationReceipt r
            JOIN r.notification n
            WHERE r.employee.id = :employeeId
            AND r.isRead = false
            AND (n.visibleTill IS NULL OR n.visibleTill > :now)
            """)
    long countUnreadForEmployee(@Param("employeeId") UUID employeeId,
                                @Param("now") LocalDateTime now);
}
