package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.AuthResponse;
import com.bodypilot.backend.model.dto.LoginRequest;
import com.bodypilot.backend.model.dto.UserProfileResponse;
import com.bodypilot.backend.model.dto.UserRegistrationRequest;
import com.bodypilot.backend.model.dto.UserResponse;
import com.bodypilot.backend.model.entity.User;
import com.bodypilot.backend.model.entity.UserProfile;
import com.bodypilot.backend.repository.GoalRepository;
import com.bodypilot.backend.repository.UserProfileRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.security.JwtService;
import com.bodypilot.backend.service.AuthService;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final GoalRepository goalRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final UserService userService;

    @Override
    public AuthResponse register(UserRegistrationRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .build();

        User savedUser = userRepository.save(user);

        UserProfile profile = UserProfile.builder()
                .user(savedUser)
                .fullName(request.getFullName())
                .build();
        userProfileRepository.save(profile);

        UserDetails userDetails = userDetailsService.loadUserByUsername(savedUser.getEmail());
        String token = jwtService.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .user(userService.getUserDetails(savedUser.getId()))
                .build();
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow();
        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String token = jwtService.generateToken(userDetails);

        return AuthResponse.builder()
                .token(token)
                .user(userService.getUserDetails(user.getId()))
                .build();
    }

}
