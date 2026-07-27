package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.auth.AuthResponse;
import com.bodypilot.backend.model.dto.auth.LoginRequest;
import com.bodypilot.backend.model.dto.auth.UserRegistrationRequest;

import com.bodypilot.backend.model.dto.auth.GoogleLoginRequest;

public interface AuthService {
    AuthResponse register(UserRegistrationRequest request);
    AuthResponse login(LoginRequest request);
    AuthResponse loginWithGoogle(GoogleLoginRequest request);
}
