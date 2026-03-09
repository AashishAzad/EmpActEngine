package com.tech909.empact.dto.request;

import com.tech909.empact.enums.LetterType;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** POST /letters/request */
@Getter
@Setter
public class RequestLetterRequest {

    @NotNull(message = "Letter type is required")
    private LetterType letterType;

    private String remarks;
}
