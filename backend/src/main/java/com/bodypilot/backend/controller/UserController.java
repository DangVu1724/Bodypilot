package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.ApiResponse;
import com.bodypilot.backend.model.dto.UserResponse;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    public ApiResponse<List<UserResponse>> getAllUsers() {
        return ApiResponse.ok("Users retrieved successfully", userService.getAllUsers());
    }

    @GetMapping("/{userId}")
    public ApiResponse<UserResponse> getUser(@PathVariable UUID userId) {
        return ApiResponse.ok("User retrieved successfully", userService.getUserDetails(userId));
    }
}
