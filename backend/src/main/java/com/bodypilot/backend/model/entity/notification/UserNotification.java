package com.bodypilot.backend.model.entity.notification;

import com.bodypilot.backend.model.entity.common.BaseEntity;
import com.bodypilot.backend.model.entity.user.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserNotification extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(nullable = false, length = 30)
    private String category; // WORKOUT, MEAL, CHECKIN, SYSTEM

    @Builder.Default
    @Column(name = "is_read", nullable = false)
    private boolean isRead = false;

    @Column(name = "route_to_push")
    private String routeToPush;
}
