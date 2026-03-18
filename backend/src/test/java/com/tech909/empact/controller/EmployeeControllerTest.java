package com.tech909.empact.controller;

import com.tech909.empact.dto.request.CreateEmployeeRequest;
import com.tech909.empact.dto.request.UpdateEmployeeRequest;
import com.tech909.empact.dto.response.EmployeeResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.service.EmployeeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EmployeeControllerTest {

    @Mock
    private EmployeeService employeeService;

    @InjectMocks
    private EmployeeController employeeController;

    @Test
    void createEmployee_returnsCreatedResponse() {
        CreateEmployeeRequest request = new CreateEmployeeRequest();
        request.setEmployeeId("EMP010");
        EmployeeResponse response = EmployeeResponse.builder().employeeId("EMP010").build();
        when(employeeService.createEmployee(request)).thenReturn(response);

        var result = employeeController.createEmployee(request);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getEmployees_returnsPagedData() {
        PagedResponse<EmployeeResponse> paged = PagedResponse.of(
                List.of(EmployeeResponse.builder().employeeId("EMP001").build()), 1, 1, 10);
        when(employeeService.getEmployees("emp", UserRole.EMPLOYEE, EmployeeStatus.ACTIVE, "Tech", 1, 10))
                .thenReturn(paged);

        var result = employeeController.getEmployees("emp", UserRole.EMPLOYEE, EmployeeStatus.ACTIVE, "Tech", 1, 10);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isEqualTo(paged);
    }

    @Test
    void updateEmployee_returnsUpdatedEmployee() {
        UUID id = UUID.randomUUID();
        UpdateEmployeeRequest request = new UpdateEmployeeRequest();
        request.setFirstName("Updated");
        EmployeeResponse response = EmployeeResponse.builder().id(id).firstName("Updated").build();
        when(employeeService.updateEmployee(id, request)).thenReturn(response);

        var result = employeeController.updateEmployee(id, request);

        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void hardDelete_returnsDeletionMessage() {
        UUID id = UUID.randomUUID();
        when(employeeService.hardDeleteEmployee(id)).thenReturn(Map.of("message", "Employee permanently deleted"));

        var result = employeeController.hardDelete(id);

        assertThat(result.getBody()).containsEntry("message", "Employee permanently deleted");
        verify(employeeService).hardDeleteEmployee(id);
    }
}
