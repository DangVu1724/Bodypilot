package com.bodypilot.backend.model.dto.nutrition;

import com.bodypilot.backend.model.enums.MealType;
import lombok.*;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealSlotDTO {
    private UUID id;
    private MealType mealType;
    private String customName;
    private Integer orderIndex;
    private Boolean isEaten;
    private List<MealItemDTO> items;
}
