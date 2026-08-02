package com.bodypilot.backend.model.dto.nutrition;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FoodCandidate {
    private UUID id;
    private String name;
    private double calories;
    private double protein;
    private double fat;
    private double carbs;
    private String categoryCode;
}
