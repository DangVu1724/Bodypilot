package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.notification.CreateNotificationRequest;
import com.bodypilot.backend.model.dto.notification.UserNotificationResponse;
import com.bodypilot.backend.model.entity.notification.UserNotification;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.repository.UserNotificationRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private final UserNotificationRepository notificationRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public List<UserNotificationResponse> getUserNotifications(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Override
    @Transactional
    public UserNotificationResponse createNotification(UUID userId, CreateNotificationRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        UserNotification notification = UserNotification.builder()
                .user(user)
                .title(request.getTitle())
                .body(request.getBody())
                .category(request.getCategory() != null ? request.getCategory().toUpperCase() : "SYSTEM")
                .isRead(false)
                .routeToPush(request.getRouteToPush())
                .build();

        UserNotification saved = notificationRepository.save(notification);
        return mapToResponse(saved);
    }

    @Override
    @Transactional
    public void markAsRead(UUID userId, UUID notificationId) {
        UserNotification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + notificationId));
        if (notification.getUser().getId().equals(userId)) {
            notification.setRead(true);
            notificationRepository.save(notification);
        }
    }

    @Override
    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsReadByUserId(userId);
    }

    @Override
    @Transactional
    public void deleteNotification(UUID userId, UUID notificationId) {
        UserNotification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found with id: " + notificationId));
        if (notification.getUser().getId().equals(userId)) {
            notificationRepository.delete(notification);
        }
    }

    private UserNotificationResponse mapToResponse(UserNotification entity) {
        return UserNotificationResponse.builder()
                .id(entity.getId())
                .title(entity.getTitle())
                .body(entity.getBody())
                .category(entity.getCategory())
                .isRead(entity.isRead())
                .routeToPush(entity.getRouteToPush())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
