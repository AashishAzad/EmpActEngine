package com.tech909.empact.repository;

import com.tech909.empact.entity.Salary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Salary Repository
 * One-to-one with Employee — findByEmployee_Id is the primary lookup.
 */
@Repository
public interface SalaryRepository extends JpaRepository<Salary, UUID> {
    Optional<Salary> findByEmployee_Id(UUID employeeId);
    boolean existsByEmployee_Id(UUID employeeId);
}
