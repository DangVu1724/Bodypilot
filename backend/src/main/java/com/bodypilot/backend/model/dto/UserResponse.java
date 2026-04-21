package com.bodypilot.backend.model.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class UserResponse {
    private UUID id;
    private String email;
    private UserProfileResponse profile;
    private UserMetricsResponse metrics;
    private GoalResponse goal;
}
