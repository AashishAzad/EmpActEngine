package com.tech909.empact.controller;

import com.tech909.empact.scheduler.ScheduledJobsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class ScheduledJobsControllerTest {

    @Mock
    private ScheduledJobsService scheduledJobsService;

    @InjectMocks
    private ScheduledJobsController scheduledJobsController;

    @Test
    void triggerAttendanceReminder_returnsSuccessMessage() {
        var result = scheduledJobsController.triggerAttendanceReminder();

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).containsEntry("message", "Attendance reminder job triggered");
        verify(scheduledJobsService).triggerAttendanceReminder();
    }

    @Test
    void triggerPayslipReminder_returnsSuccessMessage() {
        var result = scheduledJobsController.triggerPayslipReminder();

        assertThat(result.getBody()).containsEntry("message", "Payslip reminder job triggered");
        verify(scheduledJobsService).triggerPayslipReminder();
    }
}
