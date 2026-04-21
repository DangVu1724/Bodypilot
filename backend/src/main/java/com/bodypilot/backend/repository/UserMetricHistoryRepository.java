package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.UserMetricHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface UserMetricHistoryRepository extends JpaRepository<UserMetricHistory, UUID> {
    List<UserMetricHistory> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
