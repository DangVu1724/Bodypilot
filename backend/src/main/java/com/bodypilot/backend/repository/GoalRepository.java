package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Goal;
import com.bodypilot.backend.model.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface GoalRepository extends JpaRepository<Goal, UUID> {
    List<Goal> findByUser(User user);
    List<Goal> findByUserIdAndStatus(UUID userId, String status);
    boolean existsByUserId(UUID userId);
}
