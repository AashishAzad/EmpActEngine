package com.tech909.empact.controller;

import com.tech909.empact.dto.request.ActionLeaveRequest;
import com.tech909.empact.dto.request.ApplyLeaveRequest;
import com.tech909.empact.dto.response.LeaveBalanceResponse;
import com.tech909.empact.dto.response.LeaveResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.service.LeaveService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LeaveControllerTest {

    @Mock
    private LeaveService leaveService;

    @InjectMocks
    private LeaveController leaveController;

    @Test
    void applyLeave_returnsCreatedResponse() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        ApplyLeaveRequest request = new ApplyLeaveRequest();
        request.setLeaveType(LeaveType.CASUAL);
        request.setStartDate(LocalDate.of(2026, 4, 1));
        request.setEndDate(LocalDate.of(2026, 4, 2));

        LeaveResponse response = LeaveResponse.builder().employeeId(userId).status(LeaveStatus.PENDING).build();
        when(leaveService.applyLeave(userId, request)).thenReturn(response);

        var result = leaveController.applyLeave(request, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void getPendingLeaves_mapsAdminAuthorityToAdminRole() {
        User principal = new User(
                UUID.randomUUID().toString(),
                "password",
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
        );
        when(leaveService.getPendingLeaves(UserRole.ADMIN))
                .thenReturn(List.of(LeaveResponse.builder().status(LeaveStatus.PENDING).build()));

        var result = leaveController.getPendingLeaves(principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(leaveService).getPendingLeaves(UserRole.ADMIN);
    }

    @Test
    void rejectLeave_forManagerSetsRejectedStatusBeforeDelegating() {
        UUID leaveId = UUID.randomUUID();
        UUID managerId = UUID.randomUUID();
        User principal = new User(
                managerId.toString(),
                "password",
                List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))
        );

        ActionLeaveRequest request = new ActionLeaveRequest();
        request.setActionRemarks("Insufficient balance");

        when(leaveService.actionLeave(org.mockito.ArgumentMatchers.eq(leaveId),
                org.mockito.ArgumentMatchers.eq(managerId),
                org.mockito.ArgumentMatchers.any(ActionLeaveRequest.class),
                org.mockito.ArgumentMatchers.eq(UserRole.MANAGER)))
                .thenReturn(LeaveResponse.builder().id(leaveId).status(LeaveStatus.REJECTED).build());

        var result = leaveController.rejectLeave(leaveId, request, principal);

        ArgumentCaptor<ActionLeaveRequest> captor = ArgumentCaptor.forClass(ActionLeaveRequest.class);
        verify(leaveService).actionLeave(org.mockito.ArgumentMatchers.eq(leaveId),
                org.mockito.ArgumentMatchers.eq(managerId),
                captor.capture(),
                org.mockito.ArgumentMatchers.eq(UserRole.MANAGER));

        assertThat(captor.getValue().getStatus()).isEqualTo(LeaveStatus.REJECTED);
        assertThat(captor.getValue().getActionRemarks()).isEqualTo("Insufficient balance");
        assertThat(result.getBody().getStatus()).isEqualTo(LeaveStatus.REJECTED);
    }
}
