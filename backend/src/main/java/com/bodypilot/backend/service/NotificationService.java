package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.notification.CreateNotificationRequest;
import com.bodypilot.backend.model.dto.notification.UserNotificationResponse;

import java.util.List;
import java.util.UUID;

public interface NotificationService {
    List<UserNotificationResponse> getUserNotifications(UUID userId);
    long getUnreadCount(UUID userId);
    UserNotificationResponse createNotification(UUID userId, CreateNotificationRequest request);
    void markAsRead(UUID userId, UUID notificationId);
    void markAllAsRead(UUID userId);
    void deleteNotification(UUID userId, UUID notificationId);
}
