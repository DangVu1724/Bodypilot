package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Injury;
import com.bodypilot.backend.model.entity.User;
import com.bodypilot.backend.model.entity.UserInjury;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserInjuryRepository extends JpaRepository<UserInjury, UUID> {
    List<UserInjury> findAllByUserId(UUID userId);
    Optional<UserInjury> findByUserAndInjury(User user, Injury injury);
}
