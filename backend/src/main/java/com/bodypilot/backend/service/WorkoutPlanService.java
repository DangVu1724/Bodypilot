package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.workout.WorkoutPlanDTO;
import com.bodypilot.backend.model.enums.Goal;

import java.util.List;
import java.util.UUID;

public interface WorkoutPlanService {
    List<WorkoutPlanDTO> getAllPlans();
    List<WorkoutPlanDTO> getAllPlansFull();
    List<WorkoutPlanDTO> getPlansByGoal(Goal goal);
    WorkoutPlanDTO getPlanById(UUID id);
    WorkoutPlanDTO createPlan(WorkoutPlanDTO planDTO);
    WorkoutPlanDTO updatePlan(UUID id, WorkoutPlanDTO planDTO);
    void deletePlan(UUID id);
}
