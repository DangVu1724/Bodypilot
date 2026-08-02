package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.checkin.CheckInRequest;
import com.bodypilot.backend.model.dto.checkin.CheckInResultResponse;
import com.bodypilot.backend.model.dto.checkin.CheckInStatusResponse;
import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.CheckInService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;

    @GetMapping("/{userId}/check-in/status")
    public ApiResponse<CheckInStatusResponse> getCheckInStatus(@PathVariable UUID userId) {
        CheckInStatusResponse status = checkInService.getCheckInStatus(userId);
        return ApiResponse.ok("Check-in status retrieved successfully", status);
    }

    @PostMapping("/{userId}/check-in/submit")
    public ApiResponse<CheckInResultResponse> submitCheckIn(
            @PathVariable UUID userId,
            @RequestBody CheckInRequest request) {
        CheckInResultResponse result = checkInService.submitCheckIn(userId, request);
        return ApiResponse.ok("Check-in submitted successfully", result);
    }
}
