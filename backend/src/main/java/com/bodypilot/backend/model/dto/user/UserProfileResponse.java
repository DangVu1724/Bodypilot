package com.bodypilot.backend.model.dto.user;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserProfileResponse {
    private String fullName;
    private String avatarUrl;
    private boolean isAssessmentCompleted;
}
