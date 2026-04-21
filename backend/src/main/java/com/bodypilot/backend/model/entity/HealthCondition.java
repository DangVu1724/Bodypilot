package com.bodypilot.backend.model.entity;

import com.bodypilot.backend.model.enums.SeverityLevel;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "health_conditions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthCondition extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    private boolean affectsDiet;

    private boolean affectsWorkout;

    @Enumerated(EnumType.STRING)
    private SeverityLevel severityLevel;

    @Column(columnDefinition = "TEXT")
    private String dietNotes;

    @Column(columnDefinition = "TEXT")
    private String workoutNotes;

    @Builder.Default
    private boolean isActive = true;
}
