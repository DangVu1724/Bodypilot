package com.bodypilot.backend.model.dto.workout;

import lombok.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyWorkoutDTO {
    private UUID id;
    private LocalDate date;
    private String note;
    private Boolean isAiGenerated;
    private Double totalCaloriesPlanned;
    private Double totalCaloriesBurned;
    private Boolean isCompleted;
    private List<DailyWorkoutItemDTO> workoutItems;
}
