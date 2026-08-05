package com.bodypilot.backend.model.entity.user;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "user_step_history", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserStepHistory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDate date;

    @Column(name = "step_count", nullable = false)
    @Builder.Default
    private Integer stepCount = 0;

    @Column(name = "calories_burned")
    @Builder.Default
    private Double caloriesBurned = 0.0;

    @Column(name = "distance_km")
    @Builder.Default
    private Double distanceKm = 0.0;
}
