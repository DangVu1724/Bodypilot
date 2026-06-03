package com.bodypilot.backend.model.entity.nutrition;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "meal_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_slot_id", nullable = false)
    private MealSlot mealSlot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_id")
    private Food food;

    @Column(name = "serving_quantity", nullable = false)
    private BigDecimal servingQuantity;

    @Column(name = "order_index", nullable = false)
    @Builder.Default
    private Integer orderIndex = 0;

    // Snapshot fields to ensure historical data persistence
    @Column(name = "food_name_snapshot", nullable = false)
    private String foodNameSnapshot;

    @Column(name = "calories_snapshot", nullable = false)
    @Builder.Default
    private BigDecimal caloriesSnapshot = BigDecimal.ZERO;

    @Column(name = "protein_snapshot", nullable = false)
    @Builder.Default
    private BigDecimal proteinSnapshot = BigDecimal.ZERO;

    @Column(name = "fat_snapshot", nullable = false)
    @Builder.Default
    private BigDecimal fatSnapshot = BigDecimal.ZERO;

    @Column(name = "carbs_snapshot", nullable = false)
    @Builder.Default
    private BigDecimal carbsSnapshot = BigDecimal.ZERO;

    @Column(name = "fiber_snapshot", nullable = false)
    @Builder.Default
    private BigDecimal fiberSnapshot = BigDecimal.ZERO;

    @Column(name = "serving_unit_snapshot")
    private String servingUnitSnapshot;

    @Column(name = "image_url_snapshot", columnDefinition = "TEXT")
    private String imageUrlSnapshot;

    @Column(name = "is_custom")
    @Builder.Default
    private Boolean isCustom = false;

    @Column(name = "is_eaten", nullable = false)
    @Builder.Default
    private Boolean isEaten = true;
}
