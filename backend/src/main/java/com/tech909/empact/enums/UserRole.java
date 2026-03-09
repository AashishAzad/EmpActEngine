package com.tech909.empact.enums;

/**
 * UserRole Enum
 *
 * Represents the 3 roles in the RBAC system.
 * Maps directly to Prisma's UserRole enum.
 *
 * Design Pattern: Role-Based Access Control (RBAC)
 * Used by: SecurityConfig, RoleGuard, @PreAuthorize annotations
 */
public enum UserRole {
    EMPLOYEE,
    MANAGER,
    ADMIN
}
