package com.tech909.empact.service;

import com.tech909.empact.dto.request.ActionManualAttendanceRequest;
import com.tech909.empact.dto.request.ManualAttendanceRequestDto;
import com.tech909.empact.dto.request.MarkAttendanceRequest;
import com.tech909.empact.dto.response.AttendanceResponse;
import com.tech909.empact.dto.response.AttendanceSummaryResponse;
import com.tech909.empact.dto.response.ManualAttendanceRequestResponse;
import com.tech909.empact.entity.Attendance;
import com.tech909.empact.entity.ManualAttendanceRequest;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.ManualAttendanceRequestRepository;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final ManualAttendanceRequestRepository manualAttendanceRequestRepository;
    private final UserRepository userRepository;
    private final CompanyHolidayRepository holidayRepository;

    @Transactional
    public AttendanceResponse markAttendance(UUID userId, MarkAttendanceRequest request) {
        LocalDate today = LocalDate.now();

        if (isWeekend(today)) {
            throw new BusinessException("Cannot mark attendance on weekends");
        }
        if (holidayRepository.existsByDate(today)) {
            throw new BusinessException("Cannot mark attendance on a company holiday");
        }
        if (attendanceRepository.existsByEmployee_IdAndDate(userId, today)) {
            throw new ConflictException("Attendance already marked for today");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Attendance attendance = Attendance.builder()
                .id(UUID.randomUUID()) // ← Fix: manually set UUID before save
                .employee(user)
                .date(today)
                .status(AttendanceStatus.PRESENT)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .address(request.getAddress())
                .checkInTime(LocalDateTime.now())
                .build();

        Attendance saved = attendanceRepository.save(attendance);
        log.info("Attendance marked for: {} on {}", user.getEmployeeId(), today);
        return mapToResponse(saved);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getTodayAttendance(UUID userId) {
        LocalDate today = LocalDate.now();
        return attendanceRepository.findByEmployee_IdAndDate(userId, today)
                .map(a -> Map.of("marked", true, "attendance", (Object) mapToResponse(a)))
                .orElse(Map.of("marked", false));
    }

    @Transactional(readOnly = true)
    public List<AttendanceResponse> getAttendance(UUID userId, Integer month, Integer year) {
        LocalDate start;
        LocalDate end;

        if (month != null && year != null) {
            YearMonth ym = YearMonth.of(year, month);
            start = ym.atDay(1);
            end = ym.atEndOfMonth();
        } else if (year != null) {
            start = LocalDate.of(year, 1, 1);
            end = LocalDate.of(year, 12, 31);
        } else {
            YearMonth current = YearMonth.now();
            start = current.atDay(1);
            end = current.atEndOfMonth();
        }

        return attendanceRepository
                .findByEmployee_IdAndDateBetweenOrderByDateAsc(userId, start, end)
                .stream().map(this::mapToResponse).toList();
    }

    @Transactional(readOnly = true)
    public AttendanceSummaryResponse getMonthlySummary(UUID userId, int month, int year) {
        YearMonth ym    = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end   = ym.atEndOfMonth();

        Set<LocalDate> holidayDates = new HashSet<>(
                holidayRepository.findByDateBetween(start, end)
                        .stream().map(h -> h.getDate()).toList()
        );

        List<LocalDate> workingDays = new ArrayList<>();
        int holidayCount = 0;
        LocalDate cursor = start;

        while (!cursor.isAfter(end)) {
            if (isWeekend(cursor)) {
                cursor = cursor.plusDays(1);
                continue;
            }
            if (holidayDates.contains(cursor)) {
                holidayCount++;
                cursor = cursor.plusDays(1);
                continue;
            }
            workingDays.add(cursor);
            cursor = cursor.plusDays(1);
        }

        long present = attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(
                userId, start, end, AttendanceStatus.PRESENT);
        long manualApproved = attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(
                userId, start, end, AttendanceStatus.MANUAL_APPROVED);
        long leave = attendanceRepository.countByEmployee_IdAndDateBetweenAndStatus(
                userId, start, end, AttendanceStatus.LEAVE);

        int totalPresent = (int) (present + manualApproved);
        int totalLeave   = (int) leave;
        int totalWorking = workingDays.size();
        int absent       = Math.max(0, totalWorking - totalPresent - totalLeave);
        int percentage   = totalWorking > 0
                ? (int) Math.round((totalPresent * 100.0) / totalWorking) : 0;

        List<AttendanceResponse> records = attendanceRepository
                .findByEmployee_IdAndDateBetweenOrderByDateAsc(userId, start, end)
                .stream().map(this::mapToResponse).toList();

        return AttendanceSummaryResponse.builder()
                .employeeId(userId)
                .month(month)
                .year(year)
                .totalWorkingDays(totalWorking)
                .present(totalPresent)
                .absent(absent)
                .leaves(totalLeave)
                .holidays(holidayCount)
                .attendancePercentage(percentage)
                .records(records)
                .build();
    }

    @Transactional
    public ManualAttendanceRequestResponse submitManualRequest(
            UUID userId, ManualAttendanceRequestDto request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (!request.getRequestDate().isBefore(LocalDate.now())) {
            throw new BusinessException("Manual attendance request can only be for past dates");
        }
        if (attendanceRepository.existsByEmployee_IdAndDate(userId, request.getRequestDate())) {
            throw new ConflictException("Attendance already exists for: " + request.getRequestDate());
        }
        if (manualAttendanceRequestRepository.existsByEmployee_IdAndRequestDate(
                userId, request.getRequestDate())) {
            throw new ConflictException("Manual request already submitted for: " + request.getRequestDate());
        }

        ManualAttendanceRequest manual = ManualAttendanceRequest.builder()
                .id(UUID.randomUUID()) // ← Fix: manually set UUID before save
                .employee(user)
                .requestDate(request.getRequestDate())
                .reason(request.getReason())
                .status(LeaveStatus.PENDING)
                .build();

        ManualAttendanceRequest saved = manualAttendanceRequestRepository.save(manual);
        log.info("Manual attendance request submitted by: {} for date: {}",
                user.getEmployeeId(), request.getRequestDate());
        return mapManualToResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ManualAttendanceRequestResponse> getPendingManualRequests() {
        return manualAttendanceRequestRepository
                .findByStatusOrderByCreatedAtDesc(LeaveStatus.PENDING)
                .stream().map(this::mapManualToResponse).toList();
    }

    @Transactional
    public ManualAttendanceRequestResponse actionManualRequest(
            UUID requestId, UUID actionById, ActionManualAttendanceRequest request) {

        ManualAttendanceRequest manual = manualAttendanceRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "ManualAttendanceRequest", "id", requestId));

        if (!LeaveStatus.PENDING.equals(manual.getStatus())) {
            throw new BusinessException("Request has already been actioned");
        }

        User actionBy = userRepository.findById(actionById)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", actionById));

        manual.setStatus(request.getAction());
        manual.setActionBy(actionBy);
        manual.setActionDate(LocalDateTime.now());
        manual.setRemarks(request.getRemarks());
        manualAttendanceRequestRepository.save(manual);

        if (LeaveStatus.APPROVED.equals(request.getAction())) {
            if (!attendanceRepository.existsByEmployee_IdAndDate(
                    manual.getEmployee().getId(), manual.getRequestDate())) {
                attendanceRepository.save(Attendance.builder()
                        .id(UUID.randomUUID()) // ← Fix: manually set UUID before save
                        .employee(manual.getEmployee())
                        .date(manual.getRequestDate())
                        .status(AttendanceStatus.MANUAL_APPROVED)
                        .checkInTime(manual.getRequestDate().atTime(9, 0))
                        .build());
                log.info("Manual attendance approved for: {} on {}",
                        manual.getEmployee().getEmployeeId(), manual.getRequestDate());
            }
        }

        return mapManualToResponse(manual);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private boolean isWeekend(LocalDate date) {
        DayOfWeek day = date.getDayOfWeek();
        return day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
    }

    private AttendanceResponse mapToResponse(Attendance a) {
        AttendanceResponse.EmployeeInfo empInfo = null;
        if (a.getEmployee() != null) {
            empInfo = AttendanceResponse.EmployeeInfo.builder()
                    .employeeId(a.getEmployee().getEmployeeId())
                    .firstName(a.getEmployee().getFirstName())
                    .lastName(a.getEmployee().getLastName())
                    .build();
        }
        return AttendanceResponse.builder()
                .id(a.getId())
                .employeeId(a.getEmployee() != null ? a.getEmployee().getId() : null)
                .employee(empInfo)
                .date(a.getDate())
                .status(a.getStatus())
                .latitude(a.getLatitude())
                .longitude(a.getLongitude())
                .address(a.getAddress())
                .checkInTime(a.getCheckInTime())
                .checkOutTime(a.getCheckOutTime())
                .createdAt(a.getCreatedAt())
                .build();
    }

    private ManualAttendanceRequestResponse mapManualToResponse(ManualAttendanceRequest m) {
        AttendanceResponse.EmployeeInfo empInfo = AttendanceResponse.EmployeeInfo.builder()
                .employeeId(m.getEmployee().getEmployeeId())
                .firstName(m.getEmployee().getFirstName())
                .lastName(m.getEmployee().getLastName())
                .build();

        AttendanceResponse.EmployeeInfo actionByInfo = null;
        if (m.getActionBy() != null) {
            actionByInfo = AttendanceResponse.EmployeeInfo.builder()
                    .employeeId(m.getActionBy().getEmployeeId())
                    .firstName(m.getActionBy().getFirstName())
                    .lastName(m.getActionBy().getLastName())
                    .build();
        }

        return ManualAttendanceRequestResponse.builder()
                .id(m.getId())
                .employeeId(m.getEmployee().getId())
                .employee(empInfo)
                .requestDate(m.getRequestDate())
                .reason(m.getReason())
                .status(m.getStatus())
                .actionBy(actionByInfo)
                .actionDate(m.getActionDate())
                .remarks(m.getRemarks())
                .createdAt(m.getCreatedAt())
                .build();
    }
}