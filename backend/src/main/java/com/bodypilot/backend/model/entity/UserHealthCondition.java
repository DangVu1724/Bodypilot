package com.bodypilot.backend.model.entity;

import com.bodypilot.backend.model.enums.SeverityLevel;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_health_conditions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserHealthCondition extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condition_id", nullable = false)
    private HealthCondition condition;

    @Enumerated(EnumType.STRING)
    private SeverityLevel severityOverride;

    @Column(columnDefinition = "TEXT")
    private String note;
}
