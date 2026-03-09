package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/** GET /leaves/my-balance */
@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class LeaveBalanceResponse {
    private String employeeId;
    private int casualLeaveBalance;
    private int sickLeaveBalance;
    private int allPurposeLeaveBalance;
    private int totalBalance;
    private int casualLeaveUsed;
    private int sickLeaveUsed;
    private int allPurposeLeaveUsed;
}
