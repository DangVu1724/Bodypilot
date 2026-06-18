package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.health.AllergyMaster;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserAllergyRepository extends JpaRepository<UserAllergy, UUID> {
    List<UserAllergy> findAllByUserIdAndIsActiveTrue(UUID userId);
    Optional<UserAllergy> findByUserAndAllergyMaster(User user, AllergyMaster allergyMaster);
}
