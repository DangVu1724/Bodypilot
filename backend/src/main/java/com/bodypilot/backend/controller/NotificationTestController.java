package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.FcmService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/test-notifications")
@RequiredArgsConstructor
public class NotificationTestController {

    private final FcmService fcmService;

    @PostMapping("/send")
    public ApiResponse<String> sendTestNotification(
            @RequestParam String token,
            @RequestParam String title,
            @RequestParam String body) {
        
        String result = fcmService.sendNotification(token, title, body);
        if (result != null) {
            return ApiResponse.ok("Notification sent successfully", result);
        } else {
            return ApiResponse.error("Failed to send notification. Please check logs.");
        }
    }
}
