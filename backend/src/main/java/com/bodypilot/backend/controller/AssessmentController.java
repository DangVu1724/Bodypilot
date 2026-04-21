package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.ApiResponse;
import com.bodypilot.backend.model.dto.AssessmentSubmissionRequest;
import com.bodypilot.backend.service.AssessmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class AssessmentController {

    private final AssessmentService assessmentService;

    @PostMapping("/{userId}/assessment")
    public ApiResponse<Void> submitAssessment(
            @PathVariable java.util.UUID userId,
            @RequestBody AssessmentSubmissionRequest request) {
        assessmentService.submitAssessment(userId, request);
        return ApiResponse.ok("Assessment submitted successfully", null);
    }
}
