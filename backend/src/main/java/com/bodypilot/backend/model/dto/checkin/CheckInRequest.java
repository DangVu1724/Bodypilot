package com.bodypilot.backend.model.dto.checkin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckInRequest {
    private Double newWeight;
    private Double newHeightCm;
    private String adherenceLevel; // EXCELLENT, GOOD, NEEDS_WORK
    private String energyLevel;    // ENERGETIC, NORMAL, TIRED
    private String hungerLevel;    // SATISFIED, NORMAL, HUNGRY
    private String goalChoice;     // KEEP_SAME, LOSE_0_5KG, LOSE_1KG, MAINTAIN, GAIN_0_5KG, GAIN_1KG, GAIN_MUSCLE
    private Double targetWeight;
    private String workoutState;   // GOOD, MODERATE, SORE, SKIPPED
    private Boolean hasInjury;
    private java.util.List<String> injuredParts; // KNEE, WRIST, LOWER_BACK, SHOULDER, ANKLE
    private String notes;
}
