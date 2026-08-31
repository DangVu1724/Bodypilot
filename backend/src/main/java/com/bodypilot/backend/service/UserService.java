package com.bodypilot.backend.service;

import java.util.List;
import java.util.UUID;

import com.bodypilot.backend.model.dto.user.UserResponse;
import com.bodypilot.backend.model.entity.user.User;

public interface UserService {
    User getById(UUID id);

    User getUserByEmail(String email);

    UserResponse getUserDetails(UUID userId);

    List<UserResponse> getAllUsers();

    List<UserResponse> searchUsers(String query);

    boolean isProfileComplete(UUID userId);

    UserResponse updateProfile(UUID userId, com.bodypilot.backend.model.dto.user.UpdateProfileRequest request);
}
