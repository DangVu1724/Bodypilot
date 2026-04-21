package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.ApiResponse;
import com.bodypilot.backend.model.dto.UserResponse;
import com.bodypilot.backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;



    @GetMapping("/{userId}")
    public ApiResponse<UserResponse> getUser(@PathVariable java.util.UUID userId) {
        return ApiResponse.ok("User retrieved successfully", userService.getUserDetails(userId));
    }
}
