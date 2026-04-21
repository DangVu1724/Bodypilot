package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.AssessmentSubmissionRequest;
import com.bodypilot.backend.model.dto.UserRegistrationRequest;
import com.bodypilot.backend.model.dto.UserResponse;
import com.bodypilot.backend.model.entity.User;
import java.util.UUID;

public interface UserService {
    User getById(UUID id);
    UserResponse getUserDetails(UUID userId);
    boolean isProfileComplete(UUID userId);
}
