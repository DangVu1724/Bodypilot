package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.model.enums.DislikedFoodGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserFoodPreferenceRepository extends JpaRepository<UserFoodPreference, UUID> {
    List<UserFoodPreference> findAllByUserIdAndIsActiveTrue(UUID userId);
    Optional<UserFoodPreference> findByUserAndDislikedFoodGroup(User user, DislikedFoodGroup dislikedFoodGroup);
}
