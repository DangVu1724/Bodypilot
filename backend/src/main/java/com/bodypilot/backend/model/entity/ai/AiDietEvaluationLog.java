package com.bodypilot.backend.model.entity.ai;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ai_diet_evaluation_logs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiDietEvaluationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "target_calories", precision = 10, scale = 2)
    private BigDecimal targetCalories;

    @Column(name = "raw_calories", precision = 10, scale = 2)
    private BigDecimal rawCalories;

    @Column(name = "final_calories", precision = 10, scale = 2)
    private BigDecimal finalCalories;

    @Column(name = "calorie_mape", precision = 8, scale = 4)
    private BigDecimal calorieMape;

    @Column(name = "calorie_mae", precision = 10, scale = 2)
    private BigDecimal calorieMae;

    @Column(name = "was_scaled", nullable = false)
    private Boolean wasScaled;

    @Column(name = "scale_factor", precision = 8, scale = 4)
    private BigDecimal scaleFactor;

    @Column(name = "total_items_count")
    private Integer totalItemsCount;

    @Column(name = "allergies_checked_count")
    private Integer allergiesCheckedCount;

    @Column(name = "diets_checked_count")
    private Integer dietsCheckedCount;

    @Column(name = "dislikes_checked_count")
    private Integer dislikesCheckedCount;

    @Column(name = "execution_time_ms")
    private Long executionTimeMs;

    @Column(name = "note")
    private String note;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (wasScaled == null) {
            wasScaled = false;
        }
    }
}
