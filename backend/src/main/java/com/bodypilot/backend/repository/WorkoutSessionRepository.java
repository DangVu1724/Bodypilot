package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.workout.WorkoutSession;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, UUID> {
    List<WorkoutSession> findByPlanOrderByDayNumberAsc(WorkoutPlan plan);
}
