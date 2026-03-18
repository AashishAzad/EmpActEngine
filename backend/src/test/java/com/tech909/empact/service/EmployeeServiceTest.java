package com.tech909.empact.service;

import com.tech909.empact.dto.request.CreateEmployeeRequest;
import com.tech909.empact.dto.request.UpdateEmployeeRequest;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.repository.SalaryRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EmployeeServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private SalaryRepository salaryRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private EmployeeService employeeService;

    @Test
    void createEmployee_appliesDefaultsAndEncodesPassword() {
        CreateEmployeeRequest request = new CreateEmployeeRequest();
        request.setEmployeeId("EMP010");
        request.setFirstName("Neha");
        request.setLastName("Singh");
        request.setEmail("neha@example.com");
        request.setPassword("plain-pass");
        request.setDepartment("HR");
        request.setDesignation("Executive");
        request.setDateOfJoining(LocalDate.of(2025, 2, 1));
        request.setRole(null);
        request.setStatus(null);
        request.setCasualLeaveBalance(null);
        request.setSickLeaveBalance(null);
        request.setAllPurposeLeaveBalance(null);

        when(userRepository.existsByEmployeeId("EMP010")).thenReturn(false);
        when(userRepository.existsByEmail("neha@example.com")).thenReturn(false);
        when(passwordEncoder.encode("plain-pass")).thenReturn("encoded-pass");
        when(userRepository.save(org.mockito.ArgumentMatchers.any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        EmployeeResponse response = employeeService.createEmployee(request);

        ArgumentCaptor<User> savedUserCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(savedUserCaptor.capture());
        User savedUser = savedUserCaptor.getValue();

        assertThat(savedUser.getUsername()).isEqualTo("EMP010");
        assertThat(savedUser.getPassword()).isEqualTo("encoded-pass");
        assertThat(savedUser.getRole()).isEqualTo(UserRole.EMPLOYEE);
        assertThat(savedUser.getStatus()).isEqualTo(EmployeeStatus.ACTIVE);
        assertThat(savedUser.getCasualLeaveBalance()).isEqualTo(8);
        assertThat(savedUser.getSickLeaveBalance()).isEqualTo(8);
        assertThat(savedUser.getAllPurposeLeaveBalance()).isEqualTo(10);
        assertThat(response.getEmployeeId()).isEqualTo("EMP010");
    }

    @Test
    void createEmployee_withDuplicateEmployeeId_throwsConflictException() {
        CreateEmployeeRequest request = new CreateEmployeeRequest();
        request.setEmployeeId("EMP001");
        request.setEmail("duplicate@example.com");

        when(userRepository.existsByEmployeeId("EMP001")).thenReturn(true);

        assertThatThrownBy(() -> employeeService.createEmployee(request))
                .isInstanceOf(ConflictException.class)
                .hasMessage("Employee ID already exists: EMP001");
    }

    @Test
    void updateEmployee_updatesSelectedFieldsAndEncodesPassword() {
        UUID userId = UUID.randomUUID();
        User existingUser = new User();
        existingUser.setId(userId);
        existingUser.setEmployeeId("EMP100");
        existingUser.setEmail("old@example.com");
        existingUser.setFirstName("Old");
        existingUser.setDepartment("Sales");

        UpdateEmployeeRequest request = new UpdateEmployeeRequest();
        request.setFirstName("Updated");
        request.setEmail("updated@example.com");
        request.setDepartment("Finance");
        request.setPassword("new-pass");

        when(userRepository.findById(userId)).thenReturn(Optional.of(existingUser));
        when(userRepository.existsByEmail("updated@example.com")).thenReturn(false);
        when(passwordEncoder.encode("new-pass")).thenReturn("encoded-new-pass");
        when(userRepository.save(existingUser)).thenReturn(existingUser);

        EmployeeResponse response = employeeService.updateEmployee(userId, request);

        assertThat(existingUser.getFirstName()).isEqualTo("Updated");
        assertThat(existingUser.getEmail()).isEqualTo("updated@example.com");
        assertThat(existingUser.getDepartment()).isEqualTo("Finance");
        assertThat(existingUser.getPassword()).isEqualTo("encoded-new-pass");
        assertThat(response.getEmail()).isEqualTo("updated@example.com");
    }
}
