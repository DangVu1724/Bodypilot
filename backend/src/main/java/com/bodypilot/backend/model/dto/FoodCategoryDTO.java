package com.bodypilot.backend.model.dto;

import com.bodypilot.backend.model.enums.CategoryAppliesTo;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FoodCategoryDTO {
    private UUID id;
    private String name;
    private String code;
    private CategoryAppliesTo appliesTo;
}
