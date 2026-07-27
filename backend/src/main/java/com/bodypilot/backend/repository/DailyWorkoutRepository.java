package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.workout.DailyWorkout;
import com.bodypilot.backend.model.entity.user.User;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyWorkoutRepository extends JpaRepository<DailyWorkout, UUID> {
    
    @EntityGraph(attributePaths = {"workoutItems"})
    Optional<DailyWorkout> findByUserAndDate(User user, LocalDate date);

    @EntityGraph(attributePaths = {"workoutItems"})
    List<DailyWorkout> findByUserAndDateBetweenOrderByDateAsc(User user, LocalDate startDate, LocalDate endDate);
}
