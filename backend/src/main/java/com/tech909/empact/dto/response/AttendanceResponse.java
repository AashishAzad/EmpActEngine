package com.tech909.empact.dto.response;

import com.tech909.empact.enums.AttendanceStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/** Attendance record response — returned for mark/view operations */
@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class AttendanceResponse {

    private UUID id;
    private UUID employeeId;
    private EmployeeInfo employee;
    private LocalDate date;
    private AttendanceStatus status;
    private Double latitude;
    private Double longitude;
    private String address;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private LocalDateTime createdAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class EmployeeInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
    }
}
