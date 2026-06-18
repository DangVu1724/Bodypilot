package com.bodypilot.backend.model.entity.health;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.*;

@Entity
@Table(name = "allergy_masters")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AllergyMaster extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
