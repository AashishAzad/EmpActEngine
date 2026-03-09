package com.tech909.empact.service;

import com.tech909.empact.dto.request.ActionLeaveRequest;
import com.tech909.empact.dto.request.ApplyLeaveRequest;
import com.tech909.empact.dto.response.LeaveBalanceResponse;
import com.tech909.empact.dto.response.LeaveResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.entity.Attendance;
import com.tech909.empact.entity.Leave;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.AttendanceStatus;
import com.tech909.empact.enums.LeaveStatus;
import com.tech909.empact.enums.LeaveType;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.AttendanceRepository;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.LeaveRepository;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class LeaveService {

    private final LeaveRepository leaveRepository;
    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;
    private final CompanyHolidayRepository holidayRepository;

    @Transactional
    public LeaveResponse applyLeave(UUID userId, ApplyLeaveRequest request) {
        if (request.getStartDate().isBefore(LocalDate.now())) {
            throw new BusinessException("Leave start date cannot be in the past");
        }
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BusinessException("End date must be on or after start date");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        int numberOfDays = calculateWorkingDays(request.getStartDate(), request.getEndDate());
        if (numberOfDays == 0) {
            throw new BusinessException("Selected dates contain no working days");
        }

        int balance = getBalanceForType(user, request.getLeaveType());
        if (balance < numberOfDays) {
            throw new BusinessException(String.format(
                    "Insufficient %s leave balance. Available: %d, Required: %d",
                    request.getLeaveType(), balance, numberOfDays));
        }

        Leave leave = Leave.builder()
                .id(UUID.randomUUID())
                .employee(user)
                .leaveType(request.getLeaveType())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .numberOfDays(numberOfDays)
                .status(LeaveStatus.PENDING)
                .contactNumber(request.getContactNumber())
                .contactEmail(request.getContactEmail())
                .remarks(request.getRemarks())
                .build();

        Leave saved = leaveRepository.save(leave);
        log.info("Leave applied by {} for {} days ({} to {})",
                user.getEmployeeId(), numberOfDays,
                request.getStartDate(), request.getEndDate());
        return mapToResponse(saved);
    }

    @Transactional
    public LeaveResponse actionLeave(
            UUID leaveId, UUID actionById,
            ActionLeaveRequest request, UserRole actorRole) {

        Leave leave = leaveRepository.findById(leaveId)
                .orElseThrow(() -> new ResourceNotFoundException("Leave", "id", leaveId));

        if (!LeaveStatus.PENDING.equals(leave.getStatus())) {
            throw new BusinessException("Leave has already been actioned");
        }

        if (UserRole.MANAGER.equals(actorRole)
                && !UserRole.EMPLOYEE.equals(leave.getEmployee().getRole())) {
            throw new BusinessException("Managers can only action leaves of employees");
        }

        User actionBy = userRepository.findById(actionById)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", actionById));

        leave.setStatus(request.getStatus());
        leave.setActionBy(actionBy);
        leave.setActionDate(LocalDateTime.now());
        leave.setActionRemarks(request.getActionRemarks());
        leaveRepository.save(leave);

        if (LeaveStatus.APPROVED.equals(request.getStatus())) {
            deductLeaveBalance(leave.getEmployee(), leave.getLeaveType(), leave.getNumberOfDays());
            createLeaveAttendanceRecords(leave);
            log.info("Leave approved for {} ({} days)",
                    leave.getEmployee().getEmployeeId(), leave.getNumberOfDays());
        } else {
            log.info("Leave rejected for {}", leave.getEmployee().getEmployeeId());
        }

        return mapToResponse(leave);
    }

    @Transactional(readOnly = true)
    public List<LeaveResponse> getMyLeaves(UUID userId) {
        return leaveRepository.findLeavesFiltered(userId, null, null, null, null,
                        PageRequest.of(0, 100, Sort.by("createdAt").descending()))
                .getContent().stream().map(this::mapToResponse).toList();
    }

    @Transactional(readOnly = true)
    public LeaveBalanceResponse getMyBalance(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        return buildBalanceResponse(user);
    }

    @Transactional(readOnly = true)
    public LeaveBalanceResponse getBalanceForEmployee(UUID employeeId) {
        User user = userRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", employeeId));
        return buildBalanceResponse(user);
    }

    @Transactional(readOnly = true)
    public List<LeaveResponse> getPendingLeaves(UserRole actorRole) {
        UserRole filter = UserRole.MANAGER.equals(actorRole) ? UserRole.EMPLOYEE : null;
        return leaveRepository.findPendingLeaves(filter)
                .stream().map(this::mapToResponse).toList();
    }

    @Transactional(readOnly = true)
    public PagedResponse<LeaveResponse> getLeaves(
            UUID employeeId, LeaveStatus status, LeaveType leaveType,
            LocalDate startDate, LocalDate endDate, int page, int limit) {

        Page<Leave> result = leaveRepository.findLeavesFiltered(
                employeeId, status, leaveType, startDate, endDate,
                PageRequest.of(page - 1, limit));

        List<LeaveResponse> data = result.getContent().stream()
                .map(this::mapToResponse).toList();

        return PagedResponse.of(data, result.getTotalElements(), page, limit);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalLeaves",      leaveRepository.count());
        stats.put("pendingLeaves",    leaveRepository.countByStatus(LeaveStatus.PENDING));
        stats.put("approvedLeaves",   leaveRepository.countByStatus(LeaveStatus.APPROVED));
        stats.put("rejectedLeaves",   leaveRepository.countByStatus(LeaveStatus.REJECTED));
        stats.put("casualLeaves",     leaveRepository.countByLeaveTypeAndStatus(LeaveType.CASUAL, LeaveStatus.APPROVED));
        stats.put("sickLeaves",       leaveRepository.countByLeaveTypeAndStatus(LeaveType.SICK, LeaveStatus.APPROVED));
        stats.put("allPurposeLeaves", leaveRepository.countByLeaveTypeAndStatus(LeaveType.ALL_PURPOSE, LeaveStatus.APPROVED));
        return stats;
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    private int calculateWorkingDays(LocalDate start, LocalDate end) {
        Set<LocalDate> holidays = new HashSet<>(
                holidayRepository.findByDateBetween(start, end)
                        .stream().map(h -> h.getDate()).toList()
        );
        int count = 0;
        LocalDate cursor = start;
        while (!cursor.isAfter(end)) {
            DayOfWeek day = cursor.getDayOfWeek();
            if (day != DayOfWeek.SATURDAY && day != DayOfWeek.SUNDAY
                    && !holidays.contains(cursor)) {
                count++;
            }
            cursor = cursor.plusDays(1);
        }
        return count;
    }

    private void createLeaveAttendanceRecords(Leave leave) {
        Set<LocalDate> holidays = new HashSet<>(
                holidayRepository.findByDateBetween(
                                leave.getStartDate(), leave.getEndDate())
                        .stream().map(h -> h.getDate()).toList()
        );
        LocalDate cursor = leave.getStartDate();
        while (!cursor.isAfter(leave.getEndDate())) {
            DayOfWeek day = cursor.getDayOfWeek();
            if (day != DayOfWeek.SATURDAY && day != DayOfWeek.SUNDAY
                    && !holidays.contains(cursor)
                    && !attendanceRepository.existsByEmployee_IdAndDate(
                    leave.getEmployee().getId(), cursor)) {
                attendanceRepository.save(Attendance.builder()
                        .id(UUID.randomUUID())
                        .employee(leave.getEmployee())
                        .date(cursor)
                        .status(AttendanceStatus.LEAVE)
                        .build());
            }
            cursor = cursor.plusDays(1);
        }
    }

    private void deductLeaveBalance(User user, LeaveType type, int days) {
        switch (type) {
            case CASUAL      -> user.setCasualLeaveBalance(user.getCasualLeaveBalance() - days);
            case SICK        -> user.setSickLeaveBalance(user.getSickLeaveBalance() - days);
            case ALL_PURPOSE -> user.setAllPurposeLeaveBalance(user.getAllPurposeLeaveBalance() - days);
        }
        userRepository.save(user);
    }

    private int getBalanceForType(User user, LeaveType type) {
        return switch (type) {
            case CASUAL      -> user.getCasualLeaveBalance();
            case SICK        -> user.getSickLeaveBalance();
            case ALL_PURPOSE -> user.getAllPurposeLeaveBalance();
        };
    }

    private LeaveBalanceResponse buildBalanceResponse(User user) {
        LocalDate yearStart = LocalDate.of(LocalDate.now().getYear(), 1, 1);
        LocalDate yearEnd   = LocalDate.of(LocalDate.now().getYear(), 12, 31);

        List<Leave> approvedThisYear = leaveRepository
                .findByEmployee_IdAndStatusAndStartDateBetween(
                        user.getId(), LeaveStatus.APPROVED, yearStart, yearEnd);

        int casualUsed = approvedThisYear.stream()
                .filter(l -> LeaveType.CASUAL.equals(l.getLeaveType()))
                .mapToInt(Leave::getNumberOfDays).sum();
        int sickUsed = approvedThisYear.stream()
                .filter(l -> LeaveType.SICK.equals(l.getLeaveType()))
                .mapToInt(Leave::getNumberOfDays).sum();
        int allPurposeUsed = approvedThisYear.stream()
                .filter(l -> LeaveType.ALL_PURPOSE.equals(l.getLeaveType()))
                .mapToInt(Leave::getNumberOfDays).sum();

        return LeaveBalanceResponse.builder()
                .employeeId(user.getEmployeeId())
                .casualLeaveBalance(user.getCasualLeaveBalance())
                .sickLeaveBalance(user.getSickLeaveBalance())
                .allPurposeLeaveBalance(user.getAllPurposeLeaveBalance())
                .totalBalance(user.getCasualLeaveBalance()
                        + user.getSickLeaveBalance()
                        + user.getAllPurposeLeaveBalance())
                .casualLeaveUsed(casualUsed)
                .sickLeaveUsed(sickUsed)
                .allPurposeLeaveUsed(allPurposeUsed)
                .build();
    }

    private LeaveResponse mapToResponse(Leave l) {
        LeaveResponse.EmployeeInfo empInfo = LeaveResponse.EmployeeInfo.builder()
                .employeeId(l.getEmployee().getEmployeeId())
                .firstName(l.getEmployee().getFirstName())
                .lastName(l.getEmployee().getLastName())
                .department(l.getEmployee().getDepartment())
                .build();

        LeaveResponse.EmployeeInfo actionByInfo = null;
        if (l.getActionBy() != null) {
            actionByInfo = LeaveResponse.EmployeeInfo.builder()
                    .employeeId(l.getActionBy().getEmployeeId())
                    .firstName(l.getActionBy().getFirstName())
                    .lastName(l.getActionBy().getLastName())
                    .department(l.getActionBy().getDepartment())
                    .build();
        }

        return LeaveResponse.builder()
                .id(l.getId())
                .employeeId(l.getEmployee().getId())
                .employee(empInfo)
                .leaveType(l.getLeaveType())
                .startDate(l.getStartDate())
                .endDate(l.getEndDate())
                .numberOfDays(l.getNumberOfDays())
                .status(l.getStatus())
                .contactNumber(l.getContactNumber())
                .contactEmail(l.getContactEmail())
                .remarks(l.getRemarks())
                .actionBy(actionByInfo)
                .actionDate(l.getActionDate())
                .actionRemarks(l.getActionRemarks())
                .createdAt(l.getCreatedAt())
                .updatedAt(l.getUpdatedAt())
                .build();
    }
}