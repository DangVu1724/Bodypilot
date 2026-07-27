package com.bodypilot.backend.model.entity.workout;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "daily_workout_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyWorkoutItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_workout_id", nullable = false)
    private DailyWorkout dailyWorkout;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id")
    private Exercise exercise;

    @Column(name = "order_index", nullable = false)
    @Builder.Default
    private Integer orderIndex = 0;

    @Column(name = "is_completed", nullable = false)
    @Builder.Default
    private Boolean isCompleted = false;

    // Snapshot fields to ensure historical data persistence
    @Column(name = "exercise_name_snapshot", nullable = false)
    private String exerciseNameSnapshot;

    @Column(name = "sets_snapshot")
    private Integer setsSnapshot;

    @Column(name = "reps_snapshot")
    private Integer repsSnapshot;

    @Column(name = "weight_kg_snapshot")
    private Double weightKgSnapshot;

    @Column(name = "rest_seconds_snapshot")
    private Integer restSecondsSnapshot;

    @Column(name = "duration_minutes_snapshot")
    private Integer durationMinutesSnapshot;

    @Column(name = "distance_km_snapshot")
    private Double distanceKmSnapshot;

    @Column(name = "calories_burned_snapshot")
    @Builder.Default
    private Double caloriesBurnedSnapshot = 0.0;

    @Column(name = "is_custom")
    @Builder.Default
    private Boolean isCustom = false;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
