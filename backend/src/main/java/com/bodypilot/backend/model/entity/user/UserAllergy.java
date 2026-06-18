package com.bodypilot.backend.model.entity.user;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.entity.health.AllergyMaster;
import com.bodypilot.backend.model.enums.SeverityLevel;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "user_allergies",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"user_id", "allergy_master_id"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserAllergy extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "allergy_master_id", nullable = false)
    private AllergyMaster allergyMaster;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SeverityLevel severity;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
