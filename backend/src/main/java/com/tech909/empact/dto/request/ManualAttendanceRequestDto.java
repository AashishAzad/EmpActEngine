package com.tech909.empact.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/** POST /attendance/manual-request */
@Getter
@Setter
public class ManualAttendanceRequestDto {

    @NotNull(message = "Request date is required")
    private LocalDate requestDate;

    @NotBlank(message = "Reason is required")
    private String reason;
}
