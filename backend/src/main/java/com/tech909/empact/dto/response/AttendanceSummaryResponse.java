package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

/** Monthly attendance summary — returned by GET /attendance/summary */
@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class AttendanceSummaryResponse {
    private UUID employeeId;
    private int month;
    private int year;
    private int totalWorkingDays;
    private int present;
    private int absent;
    private int leaves;
    private int holidays;
    private int attendancePercentage;
    private List<AttendanceResponse> records;
}
