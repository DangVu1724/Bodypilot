package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.user.UserStepHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserStepHistoryRepository extends JpaRepository<UserStepHistory, UUID> {

    Optional<UserStepHistory> findByUserIdAndDate(UUID userId, LocalDate date);

    List<UserStepHistory> findAllByUserIdAndDateBetweenOrderByDateDesc(UUID userId, LocalDate startDate, LocalDate endDate);

    List<UserStepHistory> findAllByUserIdOrderByDateDesc(UUID userId);
}
