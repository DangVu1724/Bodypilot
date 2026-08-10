package com.bodypilot.backend.model.dto.checkin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckInStatusResponse {
    private boolean isCheckInDue;
    private boolean onboardingNeeded;
    private LocalDate lastCheckInDate;
    private long daysSinceLastCheckIn;
    private Double currentWeight;
    private Double currentHeightCm;
    private String currentGoal;
    private String goalDescription;
}
