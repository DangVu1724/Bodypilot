package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.user.AssessmentSubmissionRequest;
import java.util.UUID;

public interface AssessmentService {
    void submitAssessment(UUID userId, AssessmentSubmissionRequest request);
}
