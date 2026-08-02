package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.model.dto.notification.CreateNotificationRequest;
import com.bodypilot.backend.model.dto.notification.UserNotificationResponse;
import com.bodypilot.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/{userId}/notifications")
    public ApiResponse<List<UserNotificationResponse>> getUserNotifications(@PathVariable UUID userId) {
        List<UserNotificationResponse> notifications = notificationService.getUserNotifications(userId);
        return ApiResponse.ok("Notifications retrieved successfully", notifications);
    }

    @GetMapping("/{userId}/notifications/unread-count")
    public ApiResponse<Long> getUnreadCount(@PathVariable UUID userId) {
        long count = notificationService.getUnreadCount(userId);
        return ApiResponse.ok("Unread count retrieved successfully", count);
    }

    @PostMapping("/{userId}/notifications")
    public ApiResponse<UserNotificationResponse> createNotification(
            @PathVariable UUID userId,
            @RequestBody CreateNotificationRequest request) {
        UserNotificationResponse created = notificationService.createNotification(userId, request);
        return ApiResponse.ok("Notification created successfully", created);
    }

    @PutMapping("/{userId}/notifications/{id}/read")
    public ApiResponse<Void> markAsRead(
            @PathVariable UUID userId,
            @PathVariable UUID id) {
        notificationService.markAsRead(userId, id);
        return ApiResponse.ok("Notification marked as read", null);
    }

    @PutMapping("/{userId}/notifications/read-all")
    public ApiResponse<Void> markAllAsRead(@PathVariable UUID userId) {
        notificationService.markAllAsRead(userId);
        return ApiResponse.ok("All notifications marked as read", null);
    }

    @DeleteMapping("/{userId}/notifications/{id}")
    public ApiResponse<Void> deleteNotification(
            @PathVariable UUID userId,
            @PathVariable UUID id) {
        notificationService.deleteNotification(userId, id);
        return ApiResponse.ok("Notification deleted successfully", null);
    }
}
