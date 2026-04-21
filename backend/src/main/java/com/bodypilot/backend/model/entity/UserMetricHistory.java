package com.bodypilot.backend.model.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_metric_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserMetricHistory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    private Double weight;

    @Column(name = "height_cm")
    private Double heightCm;

    private Integer age;

    private String goal;

    private String activityLevel;

    private Double bmi;

    private Double bmr;

    private Double tdee;

    private Double targetCalories;
}
