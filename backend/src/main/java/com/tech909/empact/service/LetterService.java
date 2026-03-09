package com.tech909.empact.service;

import com.tech909.empact.dto.request.RequestLetterRequest;
import com.tech909.empact.dto.response.LetterRequestResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.entity.LetterRequest;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.exception.ResourceNotFoundException;
import com.tech909.empact.repository.LetterRequestRepository;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Letter Service
 *
 * Handles official document requests:
 * - Employee requests a document (EXPERIENCE, EMPLOYMENT, FORM_16, APPRAISAL)
 * - Admin uploads the file → status becomes COMPLETED
 * - Admin can reject with remarks
 * - Employee downloads their own document
 *
 * Workflow: PENDING → COMPLETED (upload) | REJECTED
 *
 * File Storage: Local filesystem (./uploads/letters/)
 * Files named: {employeeId}_{letterType}_{timestamp}.pdf
 * In production: replace with S3/GCS/Azure Blob Storage
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LetterService {

    private final LetterRequestRepository letterRequestRepository;
    private final UserRepository userRepository;

    @Value("${app.upload.dir:./uploads/letters}")
    private String uploadDir;

    /**
     * Request a Letter/Document
     *
     * Prevents duplicate PENDING requests for the same letter type.
     * (Employee can request again once previous one is COMPLETED or REJECTED)
     *
     * @param userId  requesting employee's UUID
     * @param request letter type + optional remarks
     */
    @Transactional
    public LetterRequestResponse requestLetter(UUID userId, RequestLetterRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        // Prevent duplicate pending request for same type
        if (letterRequestRepository.existsByEmployee_IdAndLetterTypeAndStatus(
                userId, request.getLetterType(), LetterRequestStatus.PENDING)) {
            throw new ConflictException(
                    "A pending request for " + request.getLetterType()
                            + " already exists. Please wait for it to be processed.");
        }

        LetterRequest letterRequest = LetterRequest.builder()
                .id(UUID.randomUUID())
                .employee(user)
                .letterType(request.getLetterType())
                .status(LetterRequestStatus.PENDING)
                .remarks(request.getRemarks())
                .build();

        LetterRequest saved = letterRequestRepository.save(letterRequest);
        log.info("Letter request created: {} for {}", request.getLetterType(), user.getEmployeeId());
        return mapToResponse(saved);
    }

    /**
     * Upload Letter File (Admin)
     *
     * Admin uploads the completed document.
     * Saves file to local storage, stores path in DB, marks as COMPLETED.
     *
     * File naming: {employeeId}_{type}_{timestamp}.pdf
     * Prevents collisions with timestamp in filename.
     *
     * @param requestId letter request UUID
     * @param file      uploaded PDF file
     */
    @Transactional
    public LetterRequestResponse uploadLetter(UUID requestId, MultipartFile file) {
        LetterRequest letterRequest = letterRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LetterRequest", "id", requestId));

        if (LetterRequestStatus.REJECTED.equals(letterRequest.getStatus())) {
            throw new BusinessException("Cannot upload to a rejected request");
        }

        try {
            // Ensure upload directory exists
            Path uploadPath = Paths.get(uploadDir);
            Files.createDirectories(uploadPath);

            // Build unique filename: EMP001_EXPERIENCE_20260130_143022.pdf
            String timestamp = LocalDateTime.now()
                    .format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String filename = String.format("%s_%s_%s.pdf",
                    letterRequest.getEmployee().getEmployeeId(),
                    letterRequest.getLetterType().name(),
                    timestamp);

            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Update request with file path and mark COMPLETED
            letterRequest.setFileUrl(filePath.toString());
            letterRequest.setStatus(LetterRequestStatus.COMPLETED);
            letterRequest.setCompletedAt(LocalDateTime.now());
            letterRequestRepository.save(letterRequest);

            log.info("Letter uploaded for request {}: {}", requestId, filename);
        } catch (IOException e) {
            log.error("File upload failed for request {}: {}", requestId, e.getMessage());
            throw new BusinessException("File upload failed: " + e.getMessage());
        }

        return mapToResponse(letterRequest);
    }

    /**
     * Reject Letter Request (Admin)
     *
     * @param requestId letter request UUID
     * @param remarks   reason for rejection
     */
    @Transactional
    public LetterRequestResponse rejectLetter(UUID requestId, String remarks) {
        LetterRequest letterRequest = letterRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LetterRequest", "id", requestId));

        if (!LetterRequestStatus.PENDING.equals(letterRequest.getStatus())) {
            throw new BusinessException("Only PENDING requests can be rejected");
        }

        letterRequest.setStatus(LetterRequestStatus.REJECTED);
        letterRequest.setRemarks(remarks);
        letterRequestRepository.save(letterRequest);

        log.info("Letter request {} rejected", requestId);
        return mapToResponse(letterRequest);
    }

    /**
     * Get My Letter Requests (current user)
     */
    @Transactional(readOnly = true)
    public List<LetterRequestResponse> getMyRequests(UUID userId) {
        return letterRequestRepository
                .findByEmployee_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    /**
     * Get Pending Requests (Admin only)
     */
    @Transactional(readOnly = true)
    public List<LetterRequestResponse> getPendingRequests() {
        return letterRequestRepository
                .findByStatusOrderByCreatedAtDesc(LetterRequestStatus.PENDING)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    /**
     * Get All Requests — paginated + filtered (Admin)
     */
    @Transactional(readOnly = true)
    public PagedResponse<LetterRequestResponse> getAllRequests(
            UUID employeeId, LetterRequestStatus status,
            LetterType letterType, int page, int limit) {

        Page<LetterRequest> result = letterRequestRepository.findLettersFiltered(
                employeeId, status, letterType,
                PageRequest.of(page - 1, limit));

        List<LetterRequestResponse> data = result.getContent()
                .stream().map(this::mapToResponse).toList();

        return PagedResponse.of(data, result.getTotalElements(), page, limit);
    }

    /**
     * Get Letter for Download
     *
     * Returns the file path for streaming.
     * Authorization check: only the requestor can download their own letter.
     *
     * @param requestId letter request UUID
     * @param userId    requesting user's UUID (for auth check)
     * @return file path string
     */
    @Transactional(readOnly = true)
    public String getLetterForDownload(UUID requestId, UUID userId) {
        LetterRequest letterRequest = letterRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LetterRequest", "id", requestId));

        // Authorization: only the owner can download
        if (!letterRequest.getEmployee().getId().equals(userId)) {
            throw new BusinessException("You can only download your own letters");
        }

        if (!LetterRequestStatus.COMPLETED.equals(letterRequest.getStatus())) {
            throw new BusinessException("Letter is not ready for download yet");
        }

        if (letterRequest.getFileUrl() == null) {
            throw new BusinessException("File not found for this request");
        }

        return letterRequest.getFileUrl();
    }

    /**
     * Letter Statistics (Admin)
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getStatistics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("total",      letterRequestRepository.count());
        stats.put("pending",    letterRequestRepository.countByStatus(LetterRequestStatus.PENDING));
        stats.put("completed",  letterRequestRepository.countByStatus(LetterRequestStatus.COMPLETED));
        stats.put("rejected",   letterRequestRepository.countByStatus(LetterRequestStatus.REJECTED));
        stats.put("experience", letterRequestRepository.countByLetterType(LetterType.EXPERIENCE));
        stats.put("employment", letterRequestRepository.countByLetterType(LetterType.EMPLOYMENT));
        stats.put("form16",     letterRequestRepository.countByLetterType(LetterType.FORM_16));
        stats.put("appraisal",  letterRequestRepository.countByLetterType(LetterType.APPRAISAL));
        return stats;
    }

    // ── DTO Mapper ────────────────────────────────────────────────────────────

    private LetterRequestResponse mapToResponse(LetterRequest l) {
        User emp = l.getEmployee();
        return LetterRequestResponse.builder()
                .id(l.getId())
                .employeeId(emp.getId())
                .employee(LetterRequestResponse.EmployeeInfo.builder()
                        .employeeId(emp.getEmployeeId())
                        .firstName(emp.getFirstName())
                        .lastName(emp.getLastName())
                        .designation(emp.getDesignation())
                        .department(emp.getDepartment())
                        .build())
                .letterType(l.getLetterType())
                .status(l.getStatus())
                .remarks(l.getRemarks())
                .fileUrl(l.getFileUrl())
                .createdAt(l.getCreatedAt())
                .updatedAt(l.getUpdatedAt())
                .completedAt(l.getCompletedAt())
                .build();
    }
}