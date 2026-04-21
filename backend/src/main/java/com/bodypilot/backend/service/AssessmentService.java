package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.AssessmentSubmissionRequest;
import java.util.UUID;

public interface AssessmentService {
    void submitAssessment(UUID userId, AssessmentSubmissionRequest request);
}
