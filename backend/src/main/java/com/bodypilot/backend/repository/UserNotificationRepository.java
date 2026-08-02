package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.notification.UserNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserNotificationRepository extends JpaRepository<UserNotification, UUID> {

    List<UserNotification> findByUserIdOrderByCreatedAtDesc(UUID userId);

    long countByUserIdAndIsReadFalse(UUID userId);

    @Modifying
    @Query("UPDATE UserNotification n SET n.isRead = true WHERE n.user.id = :userId AND n.isRead = false")
    void markAllAsReadByUserId(@Param("userId") UUID userId);
}
