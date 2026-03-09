package com.tech909.empact.repository;

import com.tech909.empact.entity.Attendance;
import com.tech909.empact.enums.AttendanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Attendance Repository
 *
 * Key query: findByEmployeeIdAndDate — uses composite unique index
 * (idx_attendance_employee_date) for O(log n) lookup.
 */
@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, UUID> {

    /** Check if employee already marked attendance today */
    Optional<Attendance> findByEmployee_IdAndDate(UUID employeeId, LocalDate date);

    /** Get all attendance for an employee in a date range */
    List<Attendance> findByEmployee_IdAndDateBetweenOrderByDateAsc(
            UUID employeeId, LocalDate startDate, LocalDate endDate);

    /** Get attendance by status in a date range — used by scheduler */
    List<Attendance> findByDateBetweenAndStatus(
            LocalDate startDate, LocalDate endDate, AttendanceStatus status);

    /**
     * Get all employee IDs who have marked attendance on a specific date.
     * Used by scheduler to find employees who HAVEN'T marked attendance.
     *
     * Data Structure: Returns a Set-like list for O(1) membership check
     * after loading into a HashSet in the service layer.
     */
    @Query("SELECT a.employee.id FROM Attendance a WHERE a.date = :date")
    List<UUID> findEmployeeIdsWithAttendanceOnDate(@Param("date") LocalDate date);

    /** Monthly attendance count by status — for payslip generation */
    long countByEmployee_IdAndDateBetweenAndStatus(
            UUID employeeId, LocalDate startDate, LocalDate endDate, AttendanceStatus status);

    /** Check if attendance exists */
    boolean existsByEmployee_IdAndDate(UUID employeeId, LocalDate date);
}
