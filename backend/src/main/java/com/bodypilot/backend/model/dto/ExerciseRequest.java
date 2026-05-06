package com.bodypilot.backend.model.dto;

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
public class ExerciseRequest {
    private String code;
    private String name;
    private String description;
    private String mediaUrl;
    private String thumbnailUrl;
    private String difficulty;
    private Double metValue;
    private List<String> equipment;
    private UUID categoryId;
    private UUID bodyPartId;
    private UUID targetMuscleId;
    private List<UUID> secondaryMuscleIds;
    private Integer defaultDuration;
    private String durationUnit;
}
