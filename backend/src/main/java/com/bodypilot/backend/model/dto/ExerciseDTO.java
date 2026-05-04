package com.bodypilot.backend.model.dto;

import com.bodypilot.backend.model.enums.DifficultyLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseDTO {
    private UUID id;
    private String code;
    private String name;
    private String description;
    private String mediaUrl;
    private String thumbnailUrl;
    private DifficultyLevel difficulty;
    private Double metValue;
    private List<String> equipment;
    private WorkoutCategoryDTO category;
}
