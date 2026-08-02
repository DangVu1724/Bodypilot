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
public class ExerciseSmartSwapRequest {
    private UUID exerciseId;
}
