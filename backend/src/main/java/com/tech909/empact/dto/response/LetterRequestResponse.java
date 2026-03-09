package com.tech909.empact.dto.response;

import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class LetterRequestResponse {
    private UUID id;
    private UUID employeeId;
    private EmployeeInfo employee;
    private LetterType letterType;
    private LetterRequestStatus status;
    private String remarks;
    private String fileUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime completedAt;

    @Getter @Builder @NoArgsConstructor @AllArgsConstructor
    public static class EmployeeInfo {
        private String employeeId;
        private String firstName;
        private String lastName;
        private String designation;
        private String department;
    }
}
