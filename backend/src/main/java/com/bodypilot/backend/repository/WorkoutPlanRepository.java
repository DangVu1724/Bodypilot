package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.enums.Goal;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface WorkoutPlanRepository extends JpaRepository<WorkoutPlan, UUID> {
    List<WorkoutPlan> findByGoal(Goal goal);
}
