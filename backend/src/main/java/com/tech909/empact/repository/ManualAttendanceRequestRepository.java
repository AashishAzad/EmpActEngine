package com.tech909.empact.repository;

import com.tech909.empact.entity.ManualAttendanceRequest;
import com.tech909.empact.enums.LeaveStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * ManualAttendanceRequest Repository
 */
@Repository
public interface ManualAttendanceRequestRepository extends JpaRepository<ManualAttendanceRequest, UUID> {

    boolean existsByEmployee_IdAndRequestDate(UUID employeeId, LocalDate requestDate);

    List<ManualAttendanceRequest> findByStatusOrderByCreatedAtDesc(LeaveStatus status);

    Optional<ManualAttendanceRequest> findByEmployee_IdAndRequestDate(UUID employeeId, LocalDate date);
}
