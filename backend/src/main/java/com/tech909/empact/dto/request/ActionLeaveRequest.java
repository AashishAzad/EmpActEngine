package com.tech909.empact.dto.request;

import com.tech909.empact.enums.LeaveStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** PATCH /leaves/:id/action */
@Getter
@Setter
public class ActionLeaveRequest {

    @NotNull(message = "Status is required")
    private LeaveStatus status; // APPROVED or REJECTED

    private String actionRemarks;
}
