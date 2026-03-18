package com.tech909.empact.service;

import com.tech909.empact.dto.request.RequestLetterRequest;
import com.tech909.empact.dto.response.LetterRequestResponse;
import com.tech909.empact.entity.LetterRequest;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import com.tech909.empact.exception.BusinessException;
import com.tech909.empact.exception.ConflictException;
import com.tech909.empact.repository.LetterRequestRepository;
import com.tech909.empact.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LetterServiceTest {

    @Mock
    private LetterRequestRepository letterRequestRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private LetterService letterService;

    @TempDir
    Path tempDir;

    @Test
    void requestLetter_withDuplicatePendingRequest_throwsConflictException() {
        UUID userId = UUID.randomUUID();
        RequestLetterRequest request = new RequestLetterRequest();
        request.setLetterType(LetterType.EMPLOYMENT);

        when(userRepository.findById(userId)).thenReturn(Optional.of(buildUser(userId, "EMP001")));
        when(letterRequestRepository.existsByEmployee_IdAndLetterTypeAndStatus(
                userId, LetterType.EMPLOYMENT, LetterRequestStatus.PENDING)).thenReturn(true);

        assertThatThrownBy(() -> letterService.requestLetter(userId, request))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("A pending request for EMPLOYMENT already exists");
    }

    @Test
    void requestLetter_savesPendingRequest() {
        UUID userId = UUID.randomUUID();
        User user = buildUser(userId, "EMP001");
        RequestLetterRequest request = new RequestLetterRequest();
        request.setLetterType(LetterType.EXPERIENCE);
        request.setRemarks("Need for visa");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(letterRequestRepository.existsByEmployee_IdAndLetterTypeAndStatus(
                userId, LetterType.EXPERIENCE, LetterRequestStatus.PENDING)).thenReturn(false);
        when(letterRequestRepository.save(any(LetterRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LetterRequestResponse response = letterService.requestLetter(userId, request);

        ArgumentCaptor<LetterRequest> requestCaptor = ArgumentCaptor.forClass(LetterRequest.class);
        verify(letterRequestRepository).save(requestCaptor.capture());
        LetterRequest saved = requestCaptor.getValue();

        assertThat(saved.getStatus()).isEqualTo(LetterRequestStatus.PENDING);
        assertThat(saved.getLetterType()).isEqualTo(LetterType.EXPERIENCE);
        assertThat(response.getStatus()).isEqualTo(LetterRequestStatus.PENDING);
    }

    @Test
    void uploadLetter_forRejectedRequest_throwsBusinessException() {
        UUID requestId = UUID.randomUUID();
        LetterRequest letterRequest = LetterRequest.builder()
                .id(requestId)
                .employee(buildUser(UUID.randomUUID(), "EMP001"))
                .letterType(LetterType.EMPLOYMENT)
                .status(LetterRequestStatus.REJECTED)
                .build();

        when(letterRequestRepository.findById(requestId)).thenReturn(Optional.of(letterRequest));

        assertThatThrownBy(() -> letterService.uploadLetter(
                requestId,
                new MockMultipartFile("file", "letter.pdf", "application/pdf", "pdf".getBytes())))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Cannot upload to a rejected request");
    }

    @Test
    void uploadLetter_storesFileAndMarksRequestCompleted() throws Exception {
        UUID requestId = UUID.randomUUID();
        User user = buildUser(UUID.randomUUID(), "EMP001");
        LetterRequest letterRequest = LetterRequest.builder()
                .id(requestId)
                .employee(user)
                .letterType(LetterType.EMPLOYMENT)
                .status(LetterRequestStatus.PENDING)
                .build();

        ReflectionTestUtils.setField(letterService, "uploadDir", tempDir.toString());

        when(letterRequestRepository.findById(requestId)).thenReturn(Optional.of(letterRequest));
        when(letterRequestRepository.save(letterRequest)).thenReturn(letterRequest);

        MockMultipartFile file = new MockMultipartFile(
                "file", "letter.pdf", "application/pdf", "test-pdf-content".getBytes());

        LetterRequestResponse response = letterService.uploadLetter(requestId, file);

        assertThat(letterRequest.getStatus()).isEqualTo(LetterRequestStatus.COMPLETED);
        assertThat(letterRequest.getCompletedAt()).isNotNull();
        assertThat(letterRequest.getFileUrl()).isNotBlank();
        assertThat(Files.exists(Path.of(letterRequest.getFileUrl()))).isTrue();
        assertThat(response.getStatus()).isEqualTo(LetterRequestStatus.COMPLETED);
    }

    @Test
    void rejectLetter_onlyAllowsPendingRequests() {
        UUID requestId = UUID.randomUUID();
        LetterRequest letterRequest = LetterRequest.builder()
                .id(requestId)
                .employee(buildUser(UUID.randomUUID(), "EMP001"))
                .letterType(LetterType.EXPERIENCE)
                .status(LetterRequestStatus.COMPLETED)
                .build();

        when(letterRequestRepository.findById(requestId)).thenReturn(Optional.of(letterRequest));

        assertThatThrownBy(() -> letterService.rejectLetter(requestId, "Late"))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Only PENDING requests can be rejected");
    }

    @Test
    void getLetterForDownload_validatesOwnerAndCompletedState() {
        UUID requestId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        LetterRequest letterRequest = LetterRequest.builder()
                .id(requestId)
                .employee(buildUser(userId, "EMP001"))
                .letterType(LetterType.APPRAISAL)
                .status(LetterRequestStatus.COMPLETED)
                .fileUrl(tempDir.resolve("doc.pdf").toString())
                .build();

        when(letterRequestRepository.findById(requestId)).thenReturn(Optional.of(letterRequest));

        String result = letterService.getLetterForDownload(requestId, userId);

        assertThat(result).isEqualTo(letterRequest.getFileUrl());
    }

    @Test
    void getPendingRequests_returnsMappedResponses() {
        LetterRequest pending = LetterRequest.builder()
                .id(UUID.randomUUID())
                .employee(buildUser(UUID.randomUUID(), "EMP001"))
                .letterType(LetterType.FORM_16)
                .status(LetterRequestStatus.PENDING)
                .build();

        when(letterRequestRepository.findByStatusOrderByCreatedAtDesc(LetterRequestStatus.PENDING))
                .thenReturn(List.of(pending));

        List<LetterRequestResponse> result = letterService.getPendingRequests();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getLetterType()).isEqualTo(LetterType.FORM_16);
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
}
