package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.workout.DailyWorkoutItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface DailyWorkoutItemRepository extends JpaRepository<DailyWorkoutItem, UUID> {
}
