package com.tech909.empact.entity;

import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import io.jmix.core.HasTimeZone;
import io.jmix.core.annotation.Secret;
import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.entity.annotation.SystemLevel;
import io.jmix.core.metamodel.annotation.DependsOnProperties;
import io.jmix.core.metamodel.annotation.InstanceName;
import io.jmix.core.metamodel.annotation.JmixEntity;
import io.jmix.security.authentication.JmixUserDetails;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import org.springframework.security.core.GrantedAuthority;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Collections;
import java.util.UUID;

/**
 * User Entity — adapted for Employee Activity Management System
 *
 * This is Jmix's built-in User entity EXTENDED with all our Employee fields.
 *
 * Why we extend this instead of creating a separate Employee entity:
 * - Jmix's security system (DatabaseUserRepository, roles) is wired to this class
 * - Spring Security's UserDetailsService is also wired to this
 * - Keeping one table avoids a JOIN on every authenticated request
 *
 * Jmix required fields (kept as-is):
 * - id, version, username, password, active, timeZoneId, authorities
 *
 * Our added fields:
 * - employeeId (EMP001, MGR001, etc.)
 * - role (EMPLOYEE, MANAGER, ADMIN)
 * - all professional + contact + leave balance fields
 *
 * Table: USER_ (Jmix default — keeping it avoids migration issues)
 */
@JmixEntity
@Entity
@Table(name = "USER_", indexes = {
        @Index(name = "IDX_USER__ON_USERNAME",  columnList = "USERNAME",    unique = true),
        @Index(name = "IDX_USER__ON_EMP_ID",    columnList = "EMPLOYEE_ID", unique = true),
        @Index(name = "IDX_USER__ON_EMAIL",     columnList = "EMAIL"),
        @Index(name = "IDX_USER__ON_ROLE",      columnList = "ROLE"),
        @Index(name = "IDX_USER__ON_STATUS",    columnList = "STATUS")
})
public class User implements JmixUserDetails, HasTimeZone {

    // ── Jmix Required Fields (do NOT remove these) ───────────────────────────

    @Id
    @Column(name = "ID")
    @JmixGeneratedValue
    private UUID id;

    @Version
    @Column(name = "VERSION", nullable = false)
    private Integer version;

    /**
     * username field = used by Jmix internally.
     * We set this to employeeId (e.g. EMP001) on create
     * so Jmix auth and our login flow both work.
     */
    @Column(name = "USERNAME", nullable = false, unique = true)
    private String username;

    @Secret
    @SystemLevel
    @Column(name = "PASSWORD")
    private String password;

    @Column(name = "ACTIVE")
    private Boolean active = true;

    @Column(name = "TIME_ZONE_ID")
    private String timeZoneId;

    @Transient
    private Collection<? extends GrantedAuthority> authorities;

    // ── Our Employee Fields ───────────────────────────────────────────────────

    /**
     * Human-readable employee ID (EMP001, MGR001, ADM001).
     * This is what employees use to log in.
     * Also stored in 'username' so Jmix auth works seamlessly.
     */
    @Column(name = "EMPLOYEE_ID", unique = true, length = 20)
    private String employeeId;

    @Column(name = "FIRST_NAME")
    private String firstName;

    @Column(name = "LAST_NAME")
    private String lastName;

    @Email
    @Column(name = "EMAIL")
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "ROLE", length = 20)
    private UserRole role = UserRole.EMPLOYEE;

    @Enumerated(EnumType.STRING)
    @Column(name = "STATUS", length = 20)
    private EmployeeStatus status = EmployeeStatus.ACTIVE;

    // Professional Details
    @Column(name = "DESIGNATION", length = 100)
    private String designation;

    @Column(name = "DEPARTMENT", length = 100)
    private String department;

    @Column(name = "DATE_OF_JOINING")
    private LocalDate dateOfJoining;

    @Column(name = "QUALIFICATION", length = 200)
    private String qualification;

    // Contact Details
    @Column(name = "PHONE_NUMBER", length = 20)
    private String phoneNumber;

    @Column(name = "ADDRESS", length = 500)
    private String address;

    @Column(name = "EMERGENCY_CONTACT", length = 200)
    private String emergencyContact;

    // Leave Balances
    @Column(name = "CASUAL_LEAVE_BALANCE")
    private Integer casualLeaveBalance = 8;

    @Column(name = "SICK_LEAVE_BALANCE")
    private Integer sickLeaveBalance = 8;

    @Column(name = "ALL_PURPOSE_LEAVE_BALANCE")
    private Integer allPurposeLeaveBalance = 10;

    // Timestamps
    @Column(name = "CREATED_AT", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    @Column(name = "LAST_LOGIN")
    private LocalDateTime lastLogin;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (dateOfJoining == null) dateOfJoining = LocalDate.now();
        // Sync username with employeeId so Jmix auth works
        if (username == null && employeeId != null) username = employeeId;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // ── Jmix Required Methods (do NOT remove) ────────────────────────────────

    public UUID getId()                  { return id; }
    public void setId(UUID id)           { this.id = id; }

    public Integer getVersion()          { return version; }
    public void setVersion(Integer v)    { this.version = v; }

    @Override
    public String getUsername()          { return username; }
    public void setUsername(String u)    { this.username = u; }

    @Override
    public String getPassword()          { return password; }
    public void setPassword(String p)    { this.password = p; }

    public Boolean getActive()           { return active; }
    public void setActive(Boolean a)     { this.active = a; }

    @Override
    public String getTimeZoneId()        { return timeZoneId; }
    public void setTimeZoneId(String t)  { this.timeZoneId = t; }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities != null ? authorities : Collections.emptyList();
    }
    @Override
    public void setAuthorities(Collection<? extends GrantedAuthority> a) {
        this.authorities = a;
    }

    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled()               { return Boolean.TRUE.equals(active); }

    @InstanceName
    @DependsOnProperties({"firstName", "lastName", "username"})
    public String getDisplayName() {
        return String.format("%s %s [%s]",
                firstName != null ? firstName : "",
                lastName  != null ? lastName  : "",
                username).trim();
    }

    // ── Our Getters & Setters ─────────────────────────────────────────────────

    public String getEmployeeId()                    { return employeeId; }
    public void setEmployeeId(String employeeId) {
        this.employeeId = employeeId;
        this.username = employeeId; // always keep in sync
    }

    public String getFirstName()                     { return firstName; }
    public void setFirstName(String firstName)       { this.firstName = firstName; }

    public String getLastName()                      { return lastName; }
    public void setLastName(String lastName)         { this.lastName = lastName; }

    public String getEmail()                         { return email; }
    public void setEmail(String email)               { this.email = email; }

    public UserRole getRole()                        { return role; }
    public void setRole(UserRole role)               { this.role = role; }

    public EmployeeStatus getStatus()                { return status; }
    public void setStatus(EmployeeStatus status)     { this.status = status; }

    public String getDesignation()                   { return designation; }
    public void setDesignation(String designation)   { this.designation = designation; }

    public String getDepartment()                    { return department; }
    public void setDepartment(String department)     { this.department = department; }

    public LocalDate getDateOfJoining()              { return dateOfJoining; }
    public void setDateOfJoining(LocalDate d)        { this.dateOfJoining = d; }

    public String getQualification()                 { return qualification; }
    public void setQualification(String q)           { this.qualification = q; }

    public String getPhoneNumber()                   { return phoneNumber; }
    public void setPhoneNumber(String p)             { this.phoneNumber = p; }

    public String getAddress()                       { return address; }
    public void setAddress(String a)                 { this.address = a; }

    public String getEmergencyContact()              { return emergencyContact; }
    public void setEmergencyContact(String e)        { this.emergencyContact = e; }

    public Integer getCasualLeaveBalance()           { return casualLeaveBalance; }
    public void setCasualLeaveBalance(Integer b)     { this.casualLeaveBalance = b; }

    public Integer getSickLeaveBalance()             { return sickLeaveBalance; }
    public void setSickLeaveBalance(Integer b)       { this.sickLeaveBalance = b; }

    public Integer getAllPurposeLeaveBalance()        { return allPurposeLeaveBalance; }
    public void setAllPurposeLeaveBalance(Integer b) { this.allPurposeLeaveBalance = b; }

    public LocalDateTime getCreatedAt()              { return createdAt; }
    public LocalDateTime getUpdatedAt()              { return updatedAt; }

    public LocalDateTime getLastLogin()              { return lastLogin; }
    public void setLastLogin(LocalDateTime t)        { this.lastLogin = t; }

    // ── Utility ───────────────────────────────────────────────────────────────

    public String getFullName() {
        return firstName + " " + lastName;
    }

    public boolean isActive() {
        return EmployeeStatus.ACTIVE.equals(this.status);
    }
}