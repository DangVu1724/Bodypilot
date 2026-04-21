package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.AuthResponse;
import com.bodypilot.backend.model.dto.LoginRequest;
import com.bodypilot.backend.model.dto.UserRegistrationRequest;

public interface AuthService {
    AuthResponse register(UserRegistrationRequest request);
    AuthResponse login(LoginRequest request);
}
