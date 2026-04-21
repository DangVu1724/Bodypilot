package com.bodypilot.backend.model.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "goals")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Goal extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    private String type; // LOSE_WEIGHT, GAIN_MUSCLE, etc.

    private Double targetWeight;

    private LocalDate deadline;

    private String status; // ACTIVE, COMPLETED, ABANDONED
}
