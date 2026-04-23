package com.bodypilot.backend.model.entity;

import com.bodypilot.backend.model.enums.FoodType;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "foods")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Food extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FoodType type;

    @Column(name = "calories_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal caloriesPer100g = BigDecimal.ZERO;

    @Column(name = "protein_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal proteinPer100g = BigDecimal.ZERO;

    @Column(name = "fat_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal fatPer100g = BigDecimal.ZERO;

    @Column(name = "carbs_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal carbsPer100g = BigDecimal.ZERO;

    @Column(name = "fiber_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal fiberPer100g = BigDecimal.ZERO;

    @Column(name = "sugar_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal sugarPer100g = BigDecimal.ZERO;

    @Column(name = "sodium_mg_per_100g", nullable = false)
    @Builder.Default
    private BigDecimal sodiumMgPer100g = BigDecimal.ZERO;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private FoodCategory category;

    @Column(name = "default_serving_size")
    private BigDecimal defaultServingSize;

    @Column(name = "default_unit")
    private String defaultUnit;

    @Column(name = "image_url", columnDefinition = "TEXT")
    private String imageUrl;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "health_score")
    private Integer healthScore;

    @OneToMany(mappedBy = "food", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<FoodServing> servings = new ArrayList<>();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "food_diet_tags",
        joinColumns = @JoinColumn(name = "food_id"),
        inverseJoinColumns = @JoinColumn(name = "diet_tag_id")
    )
    @Builder.Default
    private List<DietTag> dietTags = new ArrayList<>();

    @OneToOne(mappedBy = "food", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Recipe recipe;
}
