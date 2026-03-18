package com.tech909.empact.controller;

import com.tech909.empact.dto.request.RequestLetterRequest;
import com.tech909.empact.dto.response.LetterRequestResponse;
import com.tech909.empact.enums.LetterRequestStatus;
import com.tech909.empact.enums.LetterType;
import com.tech909.empact.service.LetterService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.userdetails.User;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LetterControllerTest {

    @Mock
    private LetterService letterService;

    @InjectMocks
    private LetterController letterController;

    @TempDir
    Path tempDir;

    @Test
    void requestLetter_returnsCreatedResponse() {
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        RequestLetterRequest request = new RequestLetterRequest();
        request.setLetterType(LetterType.EMPLOYMENT);

        LetterRequestResponse response = LetterRequestResponse.builder().status(LetterRequestStatus.PENDING).build();
        when(letterService.requestLetter(userId, request)).thenReturn(response);

        var result = letterController.requestLetter(request, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(response);
    }

    @Test
    void rejectLetter_extractsRemarksFromBody() {
        UUID requestId = UUID.randomUUID();
        LetterRequestResponse response = LetterRequestResponse.builder().status(LetterRequestStatus.REJECTED).remarks("Missing details").build();
        when(letterService.rejectLetter(requestId, "Missing details")).thenReturn(response);

        var result = letterController.rejectLetter(requestId, Map.of("remarks", "Missing details"));

        assertThat(result.getBody()).isEqualTo(response);
        verify(letterService).rejectLetter(requestId, "Missing details");
    }

    @Test
    void downloadLetter_returnsPdfResourceWithAttachmentHeader() throws Exception {
        UUID requestId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        User principal = new User(userId.toString(), "password", List.of());
        Path pdf = tempDir.resolve("letter.pdf");
        Files.writeString(pdf, "pdf-content");

        when(letterService.getLetterForDownload(requestId, userId)).thenReturn(pdf.toString());

        var result = letterController.downloadLetter(requestId, principal);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getHeaders().getContentType()).isEqualTo(MediaType.APPLICATION_PDF);
        assertThat(result.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .isEqualTo("attachment; filename=\"letter.pdf\"");
        Resource body = result.getBody();
        assertThat(body).isNotNull();
        assertThat(body.exists()).isTrue();
    }
}
