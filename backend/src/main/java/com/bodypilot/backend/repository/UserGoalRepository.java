package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface UserGoalRepository extends JpaRepository<UserGoal, UUID> {
    List<UserGoal> findByUser(User user);
    List<UserGoal> findByUserIdAndStatus(UUID userId, String status);
    boolean existsByUserId(UUID userId);

    @org.springframework.data.jpa.repository.Query("SELECT new com.bodypilot.backend.model.dto.admin.AdminStatsDTO$GoalStatItem(" +
           "g.type, g.type, COUNT(g), 0.0) " +
           "FROM UserGoal g GROUP BY g.type")
    List<com.bodypilot.backend.model.dto.admin.AdminStatsDTO.GoalStatItem> findGoalCategoryCounts();
}
