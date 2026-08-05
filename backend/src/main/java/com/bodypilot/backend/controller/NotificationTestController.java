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
    private final com.bodypilot.backend.service.NotificationSchedulerService notificationSchedulerService;

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

    @PostMapping("/trigger-cron/{reminderType}")
    public ApiResponse<String> triggerCronReminder(@PathVariable String reminderType) {
        switch (reminderType.toLowerCase()) {
            case "morning":
                notificationSchedulerService.sendMorningReminder();
                break;
            case "lunch":
                notificationSchedulerService.sendLunchReminder();
                break;
            case "workout":
                notificationSchedulerService.sendAfternoonWorkoutReminder();
                break;
            case "evening":
                notificationSchedulerService.sendEveningReviewReminder();
                break;
            case "weekly":
                notificationSchedulerService.sendWeeklyReportReminder();
                break;
            default:
                return ApiResponse.error("Invalid reminderType. Use: morning, lunch, workout, evening, weekly");
        }
        return ApiResponse.ok("Successfully triggered " + reminderType + " cron notification to topic 'all_users'", null);
    }
}
