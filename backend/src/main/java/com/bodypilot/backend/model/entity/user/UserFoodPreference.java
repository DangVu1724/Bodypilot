package com.bodypilot.backend.model.entity.user;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.enums.DislikedFoodGroup;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "user_food_preferences",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"user_id", "disliked_food_group"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserFoodPreference extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "disliked_food_group", nullable = false)
    private DislikedFoodGroup dislikedFoodGroup;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
