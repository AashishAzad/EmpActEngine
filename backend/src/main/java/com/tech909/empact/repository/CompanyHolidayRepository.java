package com.tech909.empact.repository;

import com.tech909.empact.entity.CompanyHoliday;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * CompanyHoliday Repository
 *
 * Frequently queried by attendance and leave services
 * to check if a given date is a company holiday.
 * Uses idx_holiday_date index for O(log n) lookup.
 */
@Repository
public interface CompanyHolidayRepository extends JpaRepository<CompanyHoliday, UUID> {

    Optional<CompanyHoliday> findByDate(LocalDate date);

    boolean existsByDate(LocalDate date);

    /** Get all holidays between two dates — used for leave/attendance calculations */
    List<CompanyHoliday> findByDateBetween(LocalDate startDate, LocalDate endDate);
}
