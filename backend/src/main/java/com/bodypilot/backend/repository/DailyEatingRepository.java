package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.nutrition.DailyEating;
import com.bodypilot.backend.model.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyEatingRepository extends JpaRepository<DailyEating, UUID> {
    Optional<DailyEating> findByUserAndDate(User user, LocalDate date);
    List<DailyEating> findByUserAndDateBetweenOrderByDateAsc(User user, LocalDate startDate, LocalDate endDate);
}
