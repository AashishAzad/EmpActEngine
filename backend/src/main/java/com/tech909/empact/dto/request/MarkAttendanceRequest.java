package com.tech909.empact.dto.request;


import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/**
 * Mark Attendance Request DTO
 * POST /attendance/mark
 * GPS coordinates + address sent from Flutter's location package
 */
@Getter
@Setter
public class MarkAttendanceRequest {

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Invalid latitude")
    @DecimalMax(value = "90.0", message = "Invalid latitude")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Invalid longitude")
    @DecimalMax(value = "180.0", message = "Invalid longitude")
    private Double longitude;

    @NotBlank(message = "Address is required")
    private String address; // Reverse-geocoded from Flutter
}
