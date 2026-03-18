package com.tech909.empact.controller;

import com.tech909.empact.dto.request.GeneratePayslipRequest;
import com.tech909.empact.dto.request.UpsertSalaryRequest;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.dto.response.PayslipResponse;
import com.tech909.empact.dto.response.SalaryResponse;
import com.tech909.empact.service.PayrollService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.User;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PayrollControllerTest {

    @Mock
    private PayrollService payrollService;

    @InjectMocks
    private PayrollController payrollController;

    @Test
    void updateSalary_setsEmployeeIdFromPathAndReturnsOk() {
        UUID employeeId = UUID.randomUUID();
        UpsertSalaryRequest request = new UpsertSalaryRequest();
        SalaryResponse response = SalaryResponse.builder().employeeId(employeeId).build();
        when(payrollService.upsertSalary(request)).thenReturn(response);

        var result = payrollController.updateSalary(employeeId, request);

        assertThat(request.getEmployeeId()).isEqualTo(employeeId);
        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getMySalary_usesAuthenticatedUserId() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        when(payrollService.getMySalary(userId)).thenReturn(Map.of("netSalary", 44500.0));

        var result = payrollController.getMySalary(principal);

        assertThat(result.getBody()).containsEntry("netSalary", 44500.0);
    }

    @Test
    void getMyRecentPayslips_returnsServiceData() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        List<PayslipResponse> payslips = List.of(PayslipResponse.builder().month(3).year(2026).build());
        when(payrollService.getMyRecentPayslips(userId)).thenReturn(payslips);

        var result = payrollController.getMyRecentPayslips(principal);

        assertThat(result.getBody()).isEqualTo(payslips);
        verify(payrollService).getMyRecentPayslips(userId);
    }
}
