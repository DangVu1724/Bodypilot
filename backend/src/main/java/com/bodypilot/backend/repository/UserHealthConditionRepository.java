package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.HealthCondition;
import com.bodypilot.backend.model.entity.User;
import com.bodypilot.backend.model.entity.UserHealthCondition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserHealthConditionRepository extends JpaRepository<UserHealthCondition, UUID> {
    List<UserHealthCondition> findAllByUserId(UUID userId);
    Optional<UserHealthCondition> findByUserAndCondition(User user, HealthCondition condition);
}
