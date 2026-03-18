package com.tech909.empact.service;

import com.tech909.empact.dto.request.GeneratePayslipRequest;
import com.tech909.empact.dto.request.UpsertSalaryRequest;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.dto.response.PayslipResponse;
import com.tech909.empact.dto.response.SalaryResponse;
import com.tech909.empact.entity.CompanyHoliday;
import com.tech909.empact.entity.Payslip;
import com.tech909.empact.entity.Salary;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.PayslipRepository;
import com.tech909.empact.repository.SalaryRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PayrollServiceTest {

    @Mock
    private SalaryRepository salaryRepository;

    @Mock
    private PayslipRepository payslipRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private CompanyHolidayRepository holidayRepository;

    @InjectMocks
    private PayrollService payrollService;

    @Test
    void upsertSalary_createsNewSalaryAndCalculatesNetPay() {
        UUID employeeId = UUID.randomUUID();
        User user = buildUser(employeeId, "EMP001");

        UpsertSalaryRequest request = new UpsertSalaryRequest();
        request.setEmployeeId(employeeId);
        request.setBasicPay(30000.0);
        request.setHra(10000.0);
        request.setSpecialAllowance(5000.0);
        request.setOtherAllowances(2000.0);
        request.setPf(1800.0);
        request.setProfessionalTax(200.0);
        request.setOtherDeductions(500.0);

        when(userRepository.findById(employeeId)).thenReturn(Optional.of(user));
        when(salaryRepository.findByEmployee_Id(employeeId)).thenReturn(Optional.empty());
        when(salaryRepository.save(any(Salary.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SalaryResponse response = payrollService.upsertSalary(request);

        ArgumentCaptor<Salary> salaryCaptor = ArgumentCaptor.forClass(Salary.class);
        verify(salaryRepository).save(salaryCaptor.capture());
        Salary saved = salaryCaptor.getValue();

        assertThat(saved.getEmployee()).isEqualTo(user);
        assertThat(saved.getNetPay()).isEqualTo(44500.0);
        assertThat(response.getGrossPay()).isEqualTo(47000.0);
        assertThat(response.getNetPay()).isEqualTo(44500.0);
    }

    @Test
    void generatePayslip_withoutConfiguredSalary_throwsBusinessException() {
        UUID employeeId = UUID.randomUUID();
        User user = buildUser(employeeId, "EMP001");

        GeneratePayslipRequest request = new GeneratePayslipRequest();
        request.setEmployeeId(employeeId);
        request.setMonth(3);
        request.setYear(2026);

        when(userRepository.findById(employeeId)).thenReturn(Optional.of(user));
        when(salaryRepository.findByEmployee_Id(employeeId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> payrollService.generatePayslip(request))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Salary not configured for EMP001");
    }

    @Test
    void generatePayslip_whenDuplicateExists_throwsConflictException() {
        UUID employeeId = UUID.randomUUID();
        User user = buildUser(employeeId, "EMP001");
        Salary salary = buildSalary(user);

        GeneratePayslipRequest request = new GeneratePayslipRequest();
        request.setEmployeeId(employeeId);
        request.setMonth(3);
        request.setYear(2026);

        when(userRepository.findById(employeeId)).thenReturn(Optional.of(user));
        when(salaryRepository.findByEmployee_Id(employeeId)).thenReturn(Optional.of(salary));
        when(payslipRepository.existsByEmployee_IdAndMonthAndYear(employeeId, 3, 2026)).thenReturn(true);

        assertThatThrownBy(() -> payrollService.generatePayslip(request))
                .isInstanceOf(ConflictException.class)
                .hasMessage("Payslip for 3/2026 already exists for EMP001");
    }

    @Test
    void generatePayslip_appliesAbsentDayDeductionAndSavesSnapshot() {
        UUID employeeId = UUID.randomUUID();
        User user = buildUser(employeeId, "EMP001");
        Salary salary = buildSalary(user);

        GeneratePayslipRequest request = new GeneratePayslipRequest();
        request.setEmployeeId(employeeId);
        request.setMonth(3);
        request.setYear(2026);

        CompanyHoliday holiday = new CompanyHoliday();
        holiday.setDate(LocalDate.of(2026, 3, 10));

        when(userRepository.findById(employeeId)).thenReturn(Optional.of(user));
        when(salaryRepository.findByEmployee_Id(employeeId)).thenReturn(Optional.of(salary));
        when(payslipRepository.existsByEmployee_IdAndMonthAndYear(employeeId, 3, 2026)).thenReturn(false);
        when(holidayRepository.findByDateBetween(LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31)))
                .thenReturn(List.of(holiday));
        when(attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(employeeId,
                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31), AttendanceStatus.PRESENT)).thenReturn(18L);
        when(attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(employeeId,
                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31), AttendanceStatus.MANUAL_APPROVED)).thenReturn(1L);
        when(attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(employeeId,
                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31), AttendanceStatus.LEAVE)).thenReturn(1L);
        when(payslipRepository.save(any(Payslip.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PayslipResponse response = payrollService.generatePayslip(request);

        ArgumentCaptor<Payslip> payslipCaptor = ArgumentCaptor.forClass(Payslip.class);
        verify(payslipRepository).save(payslipCaptor.capture());
        Payslip saved = payslipCaptor.getValue();

        assertThat(saved.getTotalWorkingDays()).isEqualTo(21);
        assertThat(saved.getDaysPresent()).isEqualTo(19);
        assertThat(saved.getDaysOnLeave()).isEqualTo(1);
        assertThat(saved.getDaysAbsent()).isEqualTo(1);
        assertThat(saved.getNetPay()).isEqualTo(42262.0);
        assertThat(response.getNetPay()).isEqualTo(42262.0);
    }

    @Test
    void getMySalary_returnsBreakdownMap() {
        UUID employeeId = UUID.randomUUID();
        Salary salary = buildSalary(buildUser(employeeId, "EMP001"));

        when(salaryRepository.findByEmployee_Id(employeeId)).thenReturn(Optional.of(salary));

        var response = payrollService.getMySalary(employeeId);

        assertThat(response).containsEntry("grossSalary", 47000.0);
        assertThat(response).containsEntry("totalDeductions", 2500.0);
        assertThat(response).containsEntry("netSalary", 44500.0);
    }

    @Test
    void getPayslips_returnsMappedPagedResponse() {
        UUID employeeId = UUID.randomUUID();
        Payslip payslip = Payslip.builder()
                .id(UUID.randomUUID())
                .employee(buildUser(employeeId, "EMP001"))
                .month(3)
                .year(2026)
                .grossPay(47000.0)
                .netPay(44500.0)
                .daysPresent(20)
                .daysAbsent(1)
                .daysOnLeave(0)
                .totalWorkingDays(21)
                .isGenerated(true)
                .build();

        when(payslipRepository.findPayslipsFiltered(eq(employeeId), eq(3), eq(2026), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(payslip)));

        PagedResponse<PayslipResponse> response = payrollService.getPayslips(employeeId, 3, 2026, 1, 10);

        assertThat(response.getData()).hasSize(1);
        assertThat(response.getData().get(0).getMonth()).isEqualTo(3);
        assertThat(response.getTotal()).isEqualTo(1);
    }

    private User buildUser(UUID id, String employeeId) {
        User user = new User();
        user.setId(id);
        user.setEmployeeId(employeeId);
        user.setFirstName("Test");
        user.setLastName("User");
        user.setDesignation("Engineer");
        user.setDepartment("Tech");
        return user;
    }

    private Salary buildSalary(User user) {
        return Salary.builder()
                .id(UUID.randomUUID())
                .employee(user)
                .basicPay(30000.0)
                .hra(10000.0)
                .specialAllowance(5000.0)
                .otherAllowances(2000.0)
                .pf(1800.0)
                .professionalTax(200.0)
                .otherDeductions(500.0)
                .netPay(44500.0)
                .build();
    }
}
