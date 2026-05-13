package com.bodypilot.backend.model.entity.nutrition;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "food_servings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FoodServing extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_id", nullable = false)
    private Food food;

    @Column(nullable = false)
    private String name;

    @Column(name = "unit_code", nullable = false)
    @Builder.Default
    private String unitCode = "GRAM";

    @Column(nullable = false)
    private BigDecimal grams;
}
