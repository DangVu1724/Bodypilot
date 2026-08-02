package com.bodypilot.backend.model.dto.checkin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckInResultResponse {
    private Double previousWeight;
    private Double newWeight;
    private Double weightChange;
    private Double newBmr;
    private Double newTdee;
    private Double newTargetCalories;
    private String aiFeedback;
    private String advice;
}
