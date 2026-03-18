package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ActionManualAttendanceRequest;
import com.tech909.empact.dto.request.ManualAttendanceRequestDto;
import com.tech909.empact.dto.request.MarkAttendanceRequest;
import com.tech909.empact.dto.response.AttendanceResponse;
import com.tech909.empact.dto.response.AttendanceSummaryResponse;
import com.tech909.empact.dto.response.ManualAttendanceRequestResponse;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.service.AttendanceService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.User;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AttendanceControllerTest {

    @Mock
    private AttendanceService attendanceService;

    @InjectMocks
    private AttendanceController attendanceController;

    @Test
    void markAttendance_returnsCreatedResponse() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        MarkAttendanceRequest request = new MarkAttendanceRequest();
        request.setLatitude(12.0);
        request.setLongitude(77.0);
        request.setAddress("Bangalore");
        AttendanceResponse response = AttendanceResponse.builder().employeeId(userId).build();
        when(attendanceService.markAttendance(userId, request)).thenReturn(response);

        var result = attendanceController.markAttendance(request, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getTodayAttendance_returnsServicePayload() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        when(attendanceService.getTodayAttendance(userId)).thenReturn(Map.of("marked", true));

        var result = attendanceController.getTodayAttendance(principal);

        assertThat(result.getBody()).containsEntry("marked", true);
    }

    @Test
    void getMonthlySummary_usesAuthenticatedPrincipal() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        AttendanceSummaryResponse summary = AttendanceSummaryResponse.builder().employeeId(userId).month(3).year(2026).build();
        when(attendanceService.getMonthlySummary(userId, 3, 2026)).thenReturn(summary);

        var result = attendanceController.getMonthlySummary(principal, 3, 2026);

        assertThat(result.getBody()).isEqualTo(summary);
    }

    @Test
    void actionManualRequest_returnsUpdatedRequest() {
        UUID requestId = UUID.randomUUID();
        UUID adminId = UUID.randomUUID();
        User principal = new User(adminId.toString(), "password", List.of());
        ActionManualAttendanceRequest request = new ActionManualAttendanceRequest();
        request.setAction(LeaveStatus.APPROVED);
        ManualAttendanceRequestResponse response = ManualAttendanceRequestResponse.builder().id(requestId).status(LeaveStatus.APPROVED).build();
        when(attendanceService.actionManualRequest(requestId, adminId, request)).thenReturn(response);

        var result = attendanceController.actionManualRequest(requestId, request, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isEqualTo(response);
        verify(attendanceService).actionManualRequest(requestId, adminId, request);
    }
}
