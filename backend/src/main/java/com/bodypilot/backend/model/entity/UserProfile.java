package com.bodypilot.backend.model.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfile extends BaseEntity {

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private User user;

    private String fullName;

    private String gender;

    private Integer age;

    private Double heightCm;

    private Double weight;

    private Boolean hasExperience;

    private String avatarUrl;

    @Column(nullable = false)
    private boolean isAssessmentCompleted;

    private String activityLevel;
}
