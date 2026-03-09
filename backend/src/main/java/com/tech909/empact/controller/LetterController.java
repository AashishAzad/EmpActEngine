package com.tech909.empact.controller;

import com.tech909.empact.dto.request.RequestLetterRequest;
import com.tech909.empact.dto.response.LetterRequestResponse;
import com.tech909.empact.dto.response.PagedResponse;
import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import com.tech909.empact.service.LetterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Letter Controller
 * Base path: /letters (full path: /api/v1/letters)
 */
@RestController
@RequestMapping("/letters")
@RequiredArgsConstructor
public class LetterController {

    private final LetterService letterService;

    /** POST /letters/request */
    @PostMapping("/request")
    public ResponseEntity<LetterRequestResponse> requestLetter(
            @Valid @RequestBody RequestLetterRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(letterService.requestLetter(userId, request));
    }

    /** GET /letters/my-requests */
    @GetMapping("/my-requests")
    public ResponseEntity<List<LetterRequestResponse>> getMyRequests(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        return ResponseEntity.ok(letterService.getMyRequests(userId));
    }

    /** GET /letters/pending — Admin only */
    @GetMapping("/pending")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<LetterRequestResponse>> getPendingRequests() {
        return ResponseEntity.ok(letterService.getPendingRequests());
    }

    /** GET /letters?employeeId=&status=&letterType=&page=1&limit=10 — Admin only */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PagedResponse<LetterRequestResponse>> getAllRequests(
            @RequestParam(required = false) UUID employeeId,
            @RequestParam(required = false) LetterRequestStatus status,
            @RequestParam(required = false) LetterType letterType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(
                letterService.getAllRequests(employeeId, status, letterType, page, limit));
    }

    /**
     * POST /letters/{id}/upload — Admin only
     * Multipart file upload — attach the generated PDF
     */
    @PostMapping("/{id}/upload")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LetterRequestResponse> uploadLetter(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(letterService.uploadLetter(id, file));
    }

    /** PATCH /letters/{id}/reject — Admin only */
    @PatchMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LetterRequestResponse> rejectLetter(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body) {
        String remarks = body != null ? body.get("remarks") : null;
        return ResponseEntity.ok(letterService.rejectLetter(id, remarks));
    }

    /** GET /letters/statistics — Admin only */
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        return ResponseEntity.ok(letterService.getStatistics());
    }

    /**
     * GET /letters/{id}/download
     * Streams the PDF file directly to the client.
     * Authorization check inside LetterService — only the requestor can download.
     */
    @GetMapping("/{id}/download")
    public ResponseEntity<Resource> downloadLetter(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        String filePath = letterService.getLetterForDownload(id, userId);
        try {
            Path path = Paths.get(filePath);
            Resource resource = new UrlResource(path.toUri());

            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_PDF)
                    .header(HttpHeaders.CONTENT_DISPOSITION,
                            "attachment; filename=\"" + path.getFileName() + "\"")
                    .body(resource);
        } catch (MalformedURLException e) {
            throw new RuntimeException("Could not read file: " + filePath);
        }
    }
}
