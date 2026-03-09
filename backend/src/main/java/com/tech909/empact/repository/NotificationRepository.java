package com.tech909.empact.repository;

import com.tech909.empact.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Notification Repository
 * Used primarily by the scheduler for cleanup of old notifications.
 */
@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    /** For cleanup job — delete notifications older than 30 days */
    List<Notification> findByCreatedAtBefore(LocalDateTime cutoff);
    void deleteByCreatedAtBefore(LocalDateTime cutoff);
}