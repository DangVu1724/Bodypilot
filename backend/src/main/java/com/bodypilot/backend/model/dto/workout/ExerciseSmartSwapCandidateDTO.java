package com.bodypilot.backend.model.dto.workout;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseSmartSwapCandidateDTO {
    private UUID exerciseId;
    private String name;
    private String bodyPartName;
    private String targetMuscleName;
    private String difficulty;
    private Double metValue;
    private String mediaUrl;
    private Double matchScore;
    private String matchReason;
}
