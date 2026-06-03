package com.bodypilot.backend.model.entity.nutrition;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.enums.MealType;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "meal_slots")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealSlot extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_eating_id", nullable = false)
    private DailyEating dailyEating;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false)
    private MealType mealType;

    @Column(name = "custom_name")
    private String customName;

    @Column(name = "order_index", nullable = false)
    @Builder.Default
    private Integer orderIndex = 0;

    @Column(name = "is_eaten", nullable = false)
    @Builder.Default
    private Boolean isEaten = false;

    @OneToMany(mappedBy = "mealSlot", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("orderIndex ASC")
    @Builder.Default
    private List<MealItem> items = new ArrayList<>();
}
