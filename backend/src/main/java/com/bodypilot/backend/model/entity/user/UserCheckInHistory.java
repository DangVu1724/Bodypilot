package com.bodypilot.backend.model.entity.user;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "user_check_in_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserCheckInHistory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "check_in_date", nullable = false)
    private LocalDate checkInDate;

    private Double weight;

    @Column(name = "height_cm")
    private Double heightCm;

    @Column(name = "adherence_level")
    private String adherenceLevel;

    @Column(name = "energy_level")
    private String energyLevel;

    @Column(name = "hunger_level")
    private String hungerLevel;

    @Column(name = "workout_state")
    private String workoutState;

    @Column(name = "has_injury")
    private Boolean hasInjury;

    @Column(name = "injured_parts", columnDefinition = "TEXT")
    private String injuredParts;

    @Column(name = "goal_choice")
    private String goalChoice;

    @Column(name = "target_weight")
    private Double targetWeight;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "new_bmr")
    private Double newBmr;

    @Column(name = "new_tdee")
    private Double newTdee;

    @Column(name = "new_target_calories")
    private Double newTargetCalories;

    @Column(name = "ai_feedback", columnDefinition = "TEXT")
    private String aiFeedback;
}
