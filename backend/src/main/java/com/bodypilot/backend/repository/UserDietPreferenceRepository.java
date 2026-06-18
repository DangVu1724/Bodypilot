package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.nutrition.DietTag;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserDietPreferenceRepository extends JpaRepository<UserDietPreference, UUID> {
    List<UserDietPreference> findAllByUserIdAndIsActiveTrue(UUID userId);
    Optional<UserDietPreference> findByUserAndDietTag(User user, DietTag dietTag);
}
