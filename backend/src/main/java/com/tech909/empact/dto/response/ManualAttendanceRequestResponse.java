package com.tech909.empact.dto.response;

import com.tech909.empact.enums.LeaveStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class ManualAttendanceRequestResponse {
    private UUID id;
    private UUID employeeId;
    private AttendanceResponse.EmployeeInfo employee;
    private LocalDate requestDate;
    private String reason;
    private LeaveStatus status;
    private AttendanceResponse.EmployeeInfo actionBy;
    private LocalDateTime actionDate;
    private String remarks;
    private LocalDateTime createdAt;
}