package com.tech909.empact.repository;

import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
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
 * UserRepository — replaces EmployeeRepository
 *
 * Works with Jmix's User entity (which holds all employee data).
 * In Jmix, the User table IS the employee table — one unified entity.
 *
 * Note: Jmix's own DatabaseUserRepository handles internal Jmix auth.
 * This repository is for our business logic (CRUD, search, filtering).
 */
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    // ── Auth lookups ─────────────────────────────────────────────────────────

    /** Used during login — username column = employeeId (e.g. EMP001) */
    Optional<User> findByUsername(String username);

    /** Used for duplicate check on create */
    Optional<User> findByEmployeeId(String employeeId);

    boolean existsByUsername(String username);
    boolean existsByEmployeeId(String employeeId);
    boolean existsByEmail(String email);

    // ── Role / Status filters ────────────────────────────────────────────────

    List<User> findByRole(UserRole role);
    List<User> findByStatus(EmployeeStatus status);
    List<User> findByRoleAndStatus(UserRole role, EmployeeStatus status);

    // ── Paginated search (used by GET /employees) ────────────────────────────

    @Query("""
            SELECT u FROM User u
            WHERE (:search IS NULL OR
                   LOWER(u.firstName)  LIKE LOWER(CONCAT('%', :search, '%')) OR
                   LOWER(u.lastName)   LIKE LOWER(CONCAT('%', :search, '%')) OR
                   LOWER(u.email)      LIKE LOWER(CONCAT('%', :search, '%')) OR
                   LOWER(u.employeeId) LIKE LOWER(CONCAT('%', :search, '%')))
            AND (:role IS NULL OR u.role = :role)
            AND (:status IS NULL OR u.status = :status)
            AND (:department IS NULL OR LOWER(u.department) = LOWER(:department))
            """)
    Page<User> searchUsers(
            @Param("search")     String search,
            @Param("role")       UserRole role,
            @Param("status")     EmployeeStatus status,
            @Param("department") String department,
            Pageable pageable
    );

    // ── Statistics ───────────────────────────────────────────────────────────

    long countByRole(UserRole role);
    long countByStatus(EmployeeStatus status);
}
