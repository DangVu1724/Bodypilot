package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.user.AssessmentSubmissionRequest;
import com.bodypilot.backend.model.dto.auth.UserRegistrationRequest;
import com.bodypilot.backend.model.dto.user.UserResponse;
import com.bodypilot.backend.model.entity.user.User;
import java.util.List;
import java.util.UUID;

public interface UserService {
    User getById(UUID id);
    User getUserByEmail(String email);
    UserResponse getUserDetails(UUID userId);
    List<UserResponse> getAllUsers();
    boolean isProfileComplete(UUID userId);
}
