package com.tech909.empact.repository;

import com.tech909.empact.entity.LetterRequest;
import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
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
 * LetterRequest Repository
 */
@Repository
public interface LetterRequestRepository extends JpaRepository<LetterRequest, UUID> {

    /** Duplicate pending request check */
    boolean existsByEmployee_IdAndLetterTypeAndStatus(
            UUID employeeId, LetterType letterType, LetterRequestStatus status);

    List<LetterRequest> findByEmployee_IdOrderByCreatedAtDesc(UUID employeeId);

    List<LetterRequest> findByStatusOrderByCreatedAtDesc(LetterRequestStatus status);

    @Query("""
            SELECT l FROM LetterRequest l
            WHERE (:employeeId IS NULL OR l.employee.id = :employeeId)
            AND (:status IS NULL OR l.status = :status)
            AND (:letterType IS NULL OR l.letterType = :letterType)
            ORDER BY l.createdAt DESC
            """)
    Page<LetterRequest> findLettersFiltered(
            @Param("employeeId") UUID employeeId,
            @Param("status") LetterRequestStatus status,
            @Param("letterType") LetterType letterType,
            Pageable pageable
    );

    long countByStatus(LetterRequestStatus status);
    long countByLetterType(LetterType letterType);
}
