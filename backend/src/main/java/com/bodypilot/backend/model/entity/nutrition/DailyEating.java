package com.bodypilot.backend.model.entity.nutrition;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.entity.user.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "daily_eatings", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyEating extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDate date;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "is_ai_generated")
    @Builder.Default
    private Boolean isAiGenerated = false;

    @Column(
            name = "total_calories_planned",
            nullable = false,
            columnDefinition = "numeric(38,2) default 0"
    )
    @Builder.Default
    private BigDecimal totalCaloriesPlanned = BigDecimal.ZERO;

    @Column(
            name = "total_calories_eaten",
            nullable = false,
            columnDefinition = "numeric(38,2) default 0"
    )
    @Builder.Default
    private BigDecimal totalCaloriesEaten = BigDecimal.ZERO;

    @OneToMany(mappedBy = "dailyEating", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("orderIndex ASC")
    @Builder.Default
    private List<MealSlot> mealSlots = new ArrayList<>();
}
