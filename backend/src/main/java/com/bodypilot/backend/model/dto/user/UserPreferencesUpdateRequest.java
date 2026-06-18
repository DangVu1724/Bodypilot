package com.bodypilot.backend.model.dto.user;

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
public class UserPreferencesUpdateRequest {
    private List<String> selectedAllergies;
    private String allergyNote;
    private UUID selectedDietTagId;
    private List<String> dislikedFoodGroups;
    private String dislikedFoodsNote;
    private String foodBudget;
}
