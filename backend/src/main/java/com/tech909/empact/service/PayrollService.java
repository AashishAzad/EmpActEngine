package com.tech909.empact.service;

import com.tech909.empact.dto.request.GeneratePayslipRequest;
import com.tech909.empact.dto.request.UpsertSalaryRequest;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.dto.response.PayslipResponse;
import com.tech909.empact.dto.response.SalaryResponse;
import com.tech909.empact.entity.Payslip;
import com.tech909.empact.entity.Salary;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Payroll Service
 *
 * Handles salary structure management and monthly payslip generation.
 *
 * Key Business Logic:
 * - Net Pay = Gross Pay - Total Deductions
 * - Gross Pay = basicPay + hra + specialAllowance + otherAllowances
 * - Total Deductions = pf + professionalTax + otherDeductions
 * - Pro-rated net pay if employee has absences: deduct per-day amount per absent day
 *
 * Design Patterns:
 * - Service Layer: all calculations here, controller stays thin
 * - Snapshot Pattern: payslip stores salary values at time of generation
 *   (salary may change later but payslip reflects what was paid that month)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PayrollService {

    private final SalaryRepository salaryRepository;
    private final PayslipRepository payslipRepository;
    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final CompanyHolidayRepository holidayRepository;

    /**
     * Create or Update Salary Structure
     *
     * Uses upsert pattern — creates if not exists, updates if exists.
     * Admin sets this once; it's used every month for payslip generation.
     *
     * @param request salary components
     * @return created/updated salary response
     */
    @Transactional
    public SalaryResponse upsertSalary(UpsertSalaryRequest request) {
        User user = userRepository.findById(request.getEmployeeId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Employee", "id", request.getEmployeeId()));

        double grossPay = request.getBasicPay()
                + request.getHra()
                + request.getSpecialAllowance()
                + nvl(request.getOtherAllowances());

        double totalDeductions = request.getPf()
                + nvl(request.getProfessionalTax())
                + nvl(request.getOtherDeductions());

        double netPay = grossPay - totalDeductions;

        // Upsert: update existing or create new
        Salary salary = salaryRepository.findByEmployee_Id(request.getEmployeeId())
                .orElse(Salary.builder().id(UUID.randomUUID()).employee(user).build());

        salary.setBasicPay(request.getBasicPay());
        salary.setHra(request.getHra());
        salary.setSpecialAllowance(request.getSpecialAllowance());
        salary.setOtherAllowances(nvl(request.getOtherAllowances()));
        salary.setPf(request.getPf());
        salary.setProfessionalTax(nvl(request.getProfessionalTax()));
        salary.setOtherDeductions(nvl(request.getOtherDeductions()));
        salary.setNetPay(netPay);

        Salary saved = salaryRepository.save(salary);
        log.info("Salary upserted for: {}", user.getEmployeeId());
        return mapToSalaryResponse(saved);
    }

    /**
     * Generate Monthly Payslip
     *
     * Algorithm:
     * 1. Validate employee exists and has salary configured
     * 2. Check payslip doesn't already exist for this month/year
     * 3. Calculate working days for the month (exclude weekends + holidays)
     * 4. Count present, absent, leave days from attendance records
     * 5. Pro-rate salary if absent days > 0
     * 6. Save payslip as snapshot
     *
     * Snapshot Pattern: stores salary values at generation time.
     * If admin updates salary later, old payslips are unaffected.
     *
     * Time Complexity: O(d + h) where d = days in month, h = holidays
     *
     * @param request employeeId, month, year
     * @return generated payslip
     */
    @Transactional
    public PayslipResponse generatePayslip(GeneratePayslipRequest request) {
        User user = userRepository.findById(request.getEmployeeId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Employee", "id", request.getEmployeeId()));

        Salary salary = salaryRepository.findByEmployee_Id(request.getEmployeeId())
                .orElseThrow(() -> new BusinessException(
                        "Salary not configured for " + user.getEmployeeId()
                                + ". Please set salary first via POST /payroll/salary"));

        // Prevent duplicate payslip
        if (payslipRepository.existsByEmployee_IdAndMonthAndYear(
                request.getEmployeeId(), request.getMonth(), request.getYear())) {
            throw new ConflictException(String.format(
                    "Payslip for %d/%d already exists for %s",
                    request.getMonth(), request.getYear(), user.getEmployeeId()));
        }

        // Calculate attendance breakdown for the month
        AttendanceBreakdown breakdown = calculateMonthlyAttendance(
                request.getEmployeeId(), request.getMonth(), request.getYear());

        double grossPay = salary.calculateGrossPay();

        // Pro-rate: deduct per-day salary for each absent day
        // Formula: perDaySalary = grossPay / totalWorkingDays
        //          deduction = perDaySalary * daysAbsent
        double netPay = salary.getNetPay();
        if (breakdown.daysAbsent() > 0 && breakdown.totalWorkingDays() > 0) {
            double perDaySalary = grossPay / breakdown.totalWorkingDays();
            double absentDeduction = perDaySalary * breakdown.daysAbsent();
            netPay = Math.round(netPay - absentDeduction);
        }

        Payslip payslip = Payslip.builder()
                .id(UUID.randomUUID())
                .employee(user)
                .month(request.getMonth())
                .year(request.getYear())
                // Snapshot of salary at time of generation
                .basicPay(salary.getBasicPay())
                .hra(salary.getHra())
                .specialAllowance(salary.getSpecialAllowance())
                .otherAllowances(salary.getOtherAllowances())
                .pf(salary.getPf())
                .professionalTax(salary.getProfessionalTax())
                .otherDeductions(salary.getOtherDeductions())
                .grossPay(grossPay)
                .netPay(netPay)
                // Attendance breakdown
                .totalWorkingDays(breakdown.totalWorkingDays())
                .daysPresent(breakdown.daysPresent())
                .daysAbsent(breakdown.daysAbsent())
                .daysOnLeave(breakdown.daysOnLeave())
                .isGenerated(true)
                .generatedAt(LocalDateTime.now())
                .build();

        Payslip saved = payslipRepository.save(payslip);
        log.info("Payslip generated for {} — {}/{}, net pay: {}",
                user.getEmployeeId(), request.getMonth(), request.getYear(), netPay);
        return mapToPayslipResponse(saved);
    }

    /**
     * Get Salary for any employee (Admin/Manager)
     */
    @Transactional(readOnly = true)
    public SalaryResponse getSalary(UUID employeeId) {
        Salary salary = salaryRepository.findByEmployee_Id(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Salary", "employeeId", employeeId));
        return mapToSalaryResponse(salary);
    }

    /**
     * Get My Salary — simplified view for the employee themselves
     * Returns a clean breakdown: earnings, deductions, net
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getMySalary(UUID userId) {
        Salary salary = salaryRepository.findByEmployee_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Salary", "employeeId", userId));

        double gross = salary.calculateGrossPay();
        double deductions = salary.calculateTotalDeductions();

        Map<String, Object> result = new HashMap<>();
        result.put("basicPay",          salary.getBasicPay());
        result.put("hra",               salary.getHra());
        result.put("specialAllowance",  salary.getSpecialAllowance());
        result.put("otherAllowances",   salary.getOtherAllowances());
        result.put("grossSalary",       gross);
        result.put("pf",                salary.getPf());
        result.put("professionalTax",   salary.getProfessionalTax());
        result.put("otherDeductions",   salary.getOtherDeductions());
        result.put("totalDeductions",   deductions);
        result.put("netSalary",         salary.getNetPay());
        return result;
    }

    /**
     * Get paginated payslips with optional filters
     */
    @Transactional(readOnly = true)
    public PagedResponse<PayslipResponse> getPayslips(
            UUID employeeId, Integer month, Integer year, int page, int limit) {

        Page<Payslip> result = payslipRepository.findPayslipsFiltered(
                employeeId, month, year,
                PageRequest.of(page - 1, limit));

        List<PayslipResponse> data = result.getContent().stream()
                .map(this::mapToPayslipResponse).toList();

        return PagedResponse.of(data, result.getTotalElements(), page, limit);
    }

    /**
     * Get last 3 payslips for current user
     */
    @Transactional(readOnly = true)
    public List<PayslipResponse> getMyRecentPayslips(UUID userId) {
        return payslipRepository
                .findTop3ByEmployee_IdOrderByYearDescMonthDesc(userId)
                .stream()
                .map(this::mapToPayslipResponse)
                .toList();
    }

    /**
     * Payroll Statistics for Admin Dashboard
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getStatistics() {
        int currentMonth = LocalDate.now().getMonthValue();
        int currentYear  = LocalDate.now().getYear();

        long totalWithSalary    = salaryRepository.count();
        long totalPayslips      = payslipRepository.count();
        long payslipsThisMonth  = payslipRepository.countByMonthAndYear(currentMonth, currentYear);
        long pendingPayslips    = Math.max(0, totalWithSalary - payslipsThisMonth);

        // Aggregate salary stats — O(n) but bounded by employee count
        List<Salary> allSalaries = salaryRepository.findAll();
        double totalPayroll  = allSalaries.stream().mapToDouble(Salary::getNetPay).sum();
        double avgSalary     = allSalaries.isEmpty() ? 0 : totalPayroll / allSalaries.size();
        double highestSalary = allSalaries.stream().mapToDouble(Salary::getNetPay).max().orElse(0);
        double lowestSalary  = allSalaries.stream().mapToDouble(Salary::getNetPay).min().orElse(0);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalEmployeesWithSalary", totalWithSalary);
        stats.put("totalMonthlyPayroll",       Math.round(totalPayroll));
        stats.put("averageSalary",             Math.round(avgSalary));
        stats.put("highestSalary",             highestSalary);
        stats.put("lowestSalary",              lowestSalary);
        stats.put("totalPayslipsGenerated",    totalPayslips);
        stats.put("pendingPayslips",           pendingPayslips);
        return stats;
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    /**
     * Calculate attendance breakdown for a specific month.
     *
     * Algorithm:
     * 1. Get all days in month — O(d)
     * 2. Load holidays into HashSet — O(h) build, O(1) lookup
     * 3. Identify working days (skip weekends + holidays)
     * 4. Query attendance counts by status
     * 5. absent = workingDays - present - leave
     *
     * Uses Java record for clean immutable return value.
     */
    private AttendanceBreakdown calculateMonthlyAttendance(
            UUID employeeId, int month, int year) {

        YearMonth ym    = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end   = ym.atEndOfMonth();

        // HashSet for O(1) holiday lookup
        Set<LocalDate> holidays = new HashSet<>(
                holidayRepository.findByDateBetween(start, end)
                        .stream().map(h -> h.getDate()).toList()
        );

        // Count working days
        int workingDays = 0;
        LocalDate cursor = start;
        while (!cursor.isAfter(end)) {
            DayOfWeek dow = cursor.getDayOfWeek();
            if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY
                    && !holidays.contains(cursor)) {
                workingDays++;
            }
            cursor = cursor.plusDays(1);
        }

        // Count statuses from DB
        long present = attendanceRepository
                .countByEmployee_IdAndDateBetweenAndStatus(
                        employeeId, start, end, AttendanceStatus.PRESENT);
        long manualApproved = attendanceRepository
                .countByEmployee_IdAndDateBetweenAndStatus(
                        employeeId, start, end, AttendanceStatus.MANUAL_APPROVED);
        long leave = attendanceRepository
                .countByEmployee_IdAndDateBetweenAndStatus(
                        employeeId, start, end, AttendanceStatus.LEAVE);

        int totalPresent = (int) (present + manualApproved);
        int totalLeave   = (int) leave;
        int absent       = Math.max(0, workingDays - totalPresent - totalLeave);

        return new AttendanceBreakdown(workingDays, totalPresent, absent, totalLeave);
    }

    /** Null-safe double default to 0.0 */
    private double nvl(Double value) {
        return value != null ? value : 0.0;
    }

    /** Immutable record for attendance calculation result */
    private record AttendanceBreakdown(
            int totalWorkingDays,
            int daysPresent,
            int daysAbsent,
            int daysOnLeave) {}

    // ── DTO Mappers ───────────────────────────────────────────────────────────

    private SalaryResponse mapToSalaryResponse(Salary s) {
        User emp = s.getEmployee();
        return SalaryResponse.builder()
                .id(s.getId())
                .employeeId(emp.getId())
                .employee(SalaryResponse.EmployeeInfo.builder()
                        .employeeId(emp.getEmployeeId())
                        .firstName(emp.getFirstName())
                        .lastName(emp.getLastName())
                        .designation(emp.getDesignation())
                        .build())
                .basicPay(s.getBasicPay())
                .hra(s.getHra())
                .specialAllowance(s.getSpecialAllowance())
                .otherAllowances(s.getOtherAllowances())
                .pf(s.getPf())
                .professionalTax(s.getProfessionalTax())
                .otherDeductions(s.getOtherDeductions())
                .grossPay(s.calculateGrossPay())
                .netPay(s.getNetPay())
                .createdAt(s.getCreatedAt())
                .updatedAt(s.getUpdatedAt())
                .build();
    }

    private PayslipResponse mapToPayslipResponse(Payslip p) {
        User emp = p.getEmployee();
        return PayslipResponse.builder()
                .id(p.getId())
                .employeeId(emp.getId())
                .employee(PayslipResponse.EmployeeInfo.builder()
                        .employeeId(emp.getEmployeeId())
                        .firstName(emp.getFirstName())
                        .lastName(emp.getLastName())
                        .designation(emp.getDesignation())
                        .department(emp.getDepartment())
                        .build())
                .month(p.getMonth())
                .year(p.getYear())
                .basicPay(p.getBasicPay())
                .hra(p.getHra())
                .specialAllowance(p.getSpecialAllowance())
                .otherAllowances(p.getOtherAllowances())
                .pf(p.getPf())
                .professionalTax(p.getProfessionalTax())
                .otherDeductions(p.getOtherDeductions())
                .grossPay(p.getGrossPay())
                .netPay(p.getNetPay())
                .totalWorkingDays(p.getTotalWorkingDays())
                .daysPresent(p.getDaysPresent())
                .daysAbsent(p.getDaysAbsent())
                .daysOnLeave(p.getDaysOnLeave())
                .pdfUrl(p.getPdfUrl())
                .isGenerated(p.getIsGenerated())
                .generatedAt(p.getGeneratedAt())
                .createdAt(p.getCreatedAt())
                .updatedAt(p.getUpdatedAt())
                .build();
    }
}