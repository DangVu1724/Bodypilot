package com.bodypilot.backend.model.dto.user;

import com.bodypilot.backend.model.dto.health.GoalResponse;
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
