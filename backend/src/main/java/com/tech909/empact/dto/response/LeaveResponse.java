package com.tech909.empact.dto.response;

import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class LeaveResponse {
    private UUID id;
    private UUID employeeId;
    private EmployeeInfo employee;
    private LeaveType leaveType;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer numberOfDays;
    private LeaveStatus status;
    private String contactNumber;
    private String contactEmail;
    private String remarks;
    private EmployeeInfo actionBy;
    private LocalDateTime actionDate;
    private String actionRemarks;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class EmployeeInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
        private String department;
    }
}
