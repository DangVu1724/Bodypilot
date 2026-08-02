package com.bodypilot.backend.model.dto.notification;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateNotificationRequest {
    private String title;
    private String body;
    private String category; // WORKOUT, MEAL, CHECKIN, SYSTEM
    private String routeToPush;
}
