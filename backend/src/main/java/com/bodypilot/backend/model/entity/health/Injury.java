package com.bodypilot.backend.model.entity.health;

import com.bodypilot.backend.model.entity.workout.BodyPart;
import com.bodypilot.backend.model.entity.common.BaseEntity;
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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "body_part_id")
    private BodyPart bodyPart;

    @Enumerated(EnumType.STRING)
    private SeverityLevel severityLevel;

    @Builder.Default
    private boolean isActive = true;
}
