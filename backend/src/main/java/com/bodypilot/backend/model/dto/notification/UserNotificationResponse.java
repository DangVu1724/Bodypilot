package com.bodypilot.backend.model.dto.notification;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserNotificationResponse {
    private UUID id;
    private String title;
    private String body;
    private String category;
    private boolean isRead;
    private String routeToPush;
    private LocalDateTime createdAt;
}
