package com.bodypilot.backend.model.dto.workout;

import com.bodypilot.backend.model.enums.DifficultyLevel;
import com.bodypilot.backend.model.enums.Goal;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutPlanDTO {
    private UUID id;
    private String title;
    private Goal goal;
    private DifficultyLevel difficulty;
    private Integer totalDays;
    private String thumbnailUrl;
    private Boolean isPremium;
    private java.util.List<WorkoutSessionDTO> sessions;
}
