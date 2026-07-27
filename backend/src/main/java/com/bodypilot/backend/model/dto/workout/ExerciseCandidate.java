package com.bodypilot.backend.model.dto.workout;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ExerciseCandidate {
    private UUID id;
    private String name;
    private String bodyPart;
    private String targetMuscle;
    private String difficulty;
    private List<String> equipment;
}
