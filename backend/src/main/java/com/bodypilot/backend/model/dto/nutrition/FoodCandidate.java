package com.bodypilot.backend.model.dto.nutrition;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FoodCandidate {
    private UUID id;
    private String name;
    private double caloriesPer100g;
    private double proteinPer100g;
    private double fatPer100g;
    private double carbsPer100g;
    private double fiberPer100g;
    private String servingUnit;
}
