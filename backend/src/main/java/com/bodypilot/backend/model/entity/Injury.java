package com.bodypilot.backend.model.entity;

import com.bodypilot.backend.model.enums.BodyPart;
import com.bodypilot.backend.model.enums.SeverityLevel;
import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "injuries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Injury extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    private BodyPart bodyPart;

    @Enumerated(EnumType.STRING)
    private SeverityLevel severityLevel;

    @ElementCollection
    @CollectionTable(name = "injury_restricted_exercises", joinColumns = @JoinColumn(name = "injury_id"))
    @Column(name = "exercise_code")
    private List<String> restrictedExercises;

    @ElementCollection
    @CollectionTable(name = "injury_recommended_exercises", joinColumns = @JoinColumn(name = "injury_id"))
    @Column(name = "exercise_code")
    private List<String> recommendedExercises;

    @Builder.Default
    private boolean isActive = true;
}
