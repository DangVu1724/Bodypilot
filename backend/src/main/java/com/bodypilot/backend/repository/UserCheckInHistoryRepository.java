package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.user.UserCheckInHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserCheckInHistoryRepository extends JpaRepository<UserCheckInHistory, UUID> {
    Optional<UserCheckInHistory> findTopByUserIdOrderByCreatedAtDesc(UUID userId);
    List<UserCheckInHistory> findByUserIdAndCheckInDateBetweenOrderByCheckInDateAsc(UUID userId, LocalDate startDate, LocalDate endDate);
    boolean existsByUserIdAndCheckInDateBetween(UUID userId, LocalDate startDate, LocalDate endDate);
}
