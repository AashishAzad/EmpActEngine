package com.tech909.empact.dto.request;

import com.tech909.empact.enums.LeaveStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** PATCH /attendance/manual-requests/:id/action */
@Getter
@Setter
public class ActionManualAttendanceRequest {

    @NotNull(message = "Action is required")
    private LeaveStatus action; // APPROVED or REJECTED

    private String remarks;
}