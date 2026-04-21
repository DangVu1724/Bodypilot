package com.bodypilot.backend.model.entity;

import com.bodypilot.backend.model.enums.RecoveryStatus;
import com.bodypilot.backend.model.enums.SeverityLevel;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_injuries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInjury extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "injury_id", nullable = false)
    private Injury injury;

    @Enumerated(EnumType.STRING)
    private SeverityLevel severityOverride;

    @Enumerated(EnumType.STRING)
    private RecoveryStatus recoveryStatus;

    @Column(columnDefinition = "TEXT")
    private String note;
}
