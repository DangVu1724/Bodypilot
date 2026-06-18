package com.bodypilot.backend.model.entity.user;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.entity.nutrition.DietTag;
import com.bodypilot.backend.model.enums.DietAdherenceLevel;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "user_diet_preferences",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"user_id", "diet_tag_id"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDietPreference extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "diet_tag_id", nullable = false)
    private DietTag dietTag;

    @Enumerated(EnumType.STRING)
    @Column(name = "adherence_level", nullable = false)
    @Builder.Default
    private DietAdherenceLevel adherenceLevel = DietAdherenceLevel.MODERATE;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
