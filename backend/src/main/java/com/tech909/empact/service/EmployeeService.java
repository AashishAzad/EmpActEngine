package com.tech909.empact.service;

import com.tech909.empact.dto.request.CreateEmployeeRequest;
import com.tech909.empact.dto.request.UpdateEmployeeRequest;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.UserRepository;
import com.tech909.empact.repository.SalaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmployeeService {

    private final UserRepository userRepository;
    private final SalaryRepository salaryRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public EmployeeResponse createEmployee(CreateEmployeeRequest request) {
        log.info("Creating employee: {}", request.getEmployeeId());

        if (userRepository.existsByEmployeeId(request.getEmployeeId())) {
            throw new ConflictException("Employee ID already exists: " + request.getEmployeeId());
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email already in use: " + request.getEmail());
        }

        User user = new User();
        user.setEmployeeId(request.getEmployeeId());
        // username must equal employeeId so Jmix auth works
        user.setUsername(request.getEmployeeId());
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole(request.getRole() != null ? request.getRole() : UserRole.EMPLOYEE);
        user.setStatus(request.getStatus() != null ? request.getStatus() : EmployeeStatus.ACTIVE);
        user.setActive(true);
        user.setDesignation(request.getDesignation());
        user.setDepartment(request.getDepartment());
        user.setDateOfJoining(request.getDateOfJoining());
        user.setQualification(request.getQualification());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setAddress(request.getAddress());
        user.setEmergencyContact(request.getEmergencyContact());
        user.setCasualLeaveBalance(request.getCasualLeaveBalance() != null ? request.getCasualLeaveBalance() : 8);
        user.setSickLeaveBalance(request.getSickLeaveBalance() != null ? request.getSickLeaveBalance() : 8);
        user.setAllPurposeLeaveBalance(request.getAllPurposeLeaveBalance() != null ? request.getAllPurposeLeaveBalance() : 10);

        User saved = userRepository.save(user);
        log.info("Employee created: {}", saved.getEmployeeId());
        return mapToResponse(saved, false);
    }

    @Transactional(readOnly = true)
    public PagedResponse<EmployeeResponse> getEmployees(
            String search, UserRole role, EmployeeStatus status,
            String department, int page, int limit) {

        Page<User> result = userRepository.searchUsers(
                search, role, status, department,
                PageRequest.of(page - 1, limit, Sort.by("createdAt").descending()));

        List<EmployeeResponse> data = result.getContent()
                .stream().map(u -> mapToResponse(u, false)).toList();

        return PagedResponse.of(data, result.getTotalElements(), page, limit);
    }

    @Transactional(readOnly = true)
    public EmployeeResponse getEmployeeById(UUID id, boolean includeSalary) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));
        return mapToResponse(user, includeSalary);
    }

    @Transactional(readOnly = true)
    public EmployeeResponse getEmployeeByEmployeeId(String employeeId) {
        User user = userRepository.findByEmployeeId(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "employeeId", employeeId));
        return mapToResponse(user, false);
    }

    @Transactional
    public EmployeeResponse updateEmployee(UUID id, UpdateEmployeeRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));

        if (request.getEmployeeId() != null
                && !request.getEmployeeId().equals(user.getEmployeeId())
                && userRepository.existsByEmployeeId(request.getEmployeeId())) {
            throw new ConflictException("Employee ID already exists: " + request.getEmployeeId());
        }
        if (request.getEmail() != null
                && !request.getEmail().equals(user.getEmail())
                && userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email already in use: " + request.getEmail());
        }

        if (request.getEmployeeId() != null)            user.setEmployeeId(request.getEmployeeId());
        if (request.getFirstName() != null)             user.setFirstName(request.getFirstName());
        if (request.getLastName() != null)              user.setLastName(request.getLastName());
        if (request.getEmail() != null)                 user.setEmail(request.getEmail());
        if (request.getPassword() != null)              user.setPassword(passwordEncoder.encode(request.getPassword()));
        if (request.getRole() != null)                  user.setRole(request.getRole());
        if (request.getStatus() != null)                user.setStatus(request.getStatus());
        if (request.getDesignation() != null)           user.setDesignation(request.getDesignation());
        if (request.getDepartment() != null)            user.setDepartment(request.getDepartment());
        if (request.getDateOfJoining() != null)         user.setDateOfJoining(request.getDateOfJoining());
        if (request.getQualification() != null)         user.setQualification(request.getQualification());
        if (request.getPhoneNumber() != null)           user.setPhoneNumber(request.getPhoneNumber());
        if (request.getAddress() != null)               user.setAddress(request.getAddress());
        if (request.getEmergencyContact() != null)      user.setEmergencyContact(request.getEmergencyContact());
        if (request.getCasualLeaveBalance() != null)    user.setCasualLeaveBalance(request.getCasualLeaveBalance());
        if (request.getSickLeaveBalance() != null)      user.setSickLeaveBalance(request.getSickLeaveBalance());
        if (request.getAllPurposeLeaveBalance() != null) user.setAllPurposeLeaveBalance(request.getAllPurposeLeaveBalance());

        User updated = userRepository.save(user);
        log.info("Employee updated: {}", updated.getEmployeeId());
        return mapToResponse(updated, false);
    }

    @Transactional
    public Map<String, String> softDeleteEmployee(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));
        user.setStatus(EmployeeStatus.TERMINATED);
        userRepository.save(user);
        log.info("Employee terminated: {}", user.getEmployeeId());
        return Map.of("message", "Employee terminated successfully");
    }

    @Transactional
    public Map<String, String> hardDeleteEmployee(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));
        userRepository.delete(user);
        log.warn("Employee hard-deleted: {}", id);
        return Map.of("message", "Employee permanently deleted");
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalEmployees",        userRepository.count());
        stats.put("activeEmployees",       userRepository.countByStatus(EmployeeStatus.ACTIVE));
        stats.put("inactiveEmployees",     userRepository.countByStatus(EmployeeStatus.INACTIVE));
        stats.put("terminated",            userRepository.countByStatus(EmployeeStatus.TERMINATED));
        stats.put("totalManagers",         userRepository.countByRole(UserRole.MANAGER));
        stats.put("totalAdmins",           userRepository.countByRole(UserRole.ADMIN));
        stats.put("totalRegularEmployees", userRepository.countByRole(UserRole.EMPLOYEE));
        return stats;
    }

    private EmployeeResponse mapToResponse(User user, boolean includeSalary) {
        EmployeeResponse.EmployeeResponseBuilder builder = EmployeeResponse.builder()
                .id(user.getId())
                .employeeId(user.getEmployeeId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole())
                .status(user.getStatus())
                .designation(user.getDesignation())
                .department(user.getDepartment())
                .dateOfJoining(user.getDateOfJoining())
                .qualification(user.getQualification())
                .phoneNumber(user.getPhoneNumber())
                .address(user.getAddress())
                .emergencyContact(user.getEmergencyContact())
                .casualLeaveBalance(user.getCasualLeaveBalance())
                .sickLeaveBalance(user.getSickLeaveBalance())
                .allPurposeLeaveBalance(user.getAllPurposeLeaveBalance())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .lastLogin(user.getLastLogin());

        if (includeSalary) {
            salaryRepository.findByEmployee_Id(user.getId()).ifPresent(salary -> {
                builder.salary(EmployeeResponse.SalaryInfo.builder()
                        .basicPay(salary.getBasicPay())
                        .hra(salary.getHra())
                        .specialAllowance(salary.getSpecialAllowance())
                        .otherAllowances(salary.getOtherAllowances())
                        .pf(salary.getPf())
                        .professionalTax(salary.getProfessionalTax())
                        .otherDeductions(salary.getOtherDeductions())
                        .grossPay(salary.calculateGrossPay())
                        .netPay(salary.getNetPay())
                        .build());
            });
        }

        return builder.build();
    }
}