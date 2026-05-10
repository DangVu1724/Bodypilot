package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.workout.WorkoutPlanDTO;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.service.WorkoutPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workout-plans")
@RequiredArgsConstructor
public class WorkoutPlanController {

    private final WorkoutPlanService workoutPlanService;

    @GetMapping
    public ResponseEntity<List<WorkoutPlanDTO>> getAllPlans(
            @RequestParam(required = false) Goal goal) {
        if (goal != null) {
            return ResponseEntity.ok(workoutPlanService.getPlansByGoal(goal));
        }
        return ResponseEntity.ok(workoutPlanService.getAllPlans());
    }

    @GetMapping("/full")
    public ResponseEntity<List<WorkoutPlanDTO>> getAllPlansFull() {
        return ResponseEntity.ok(workoutPlanService.getAllPlansFull());
    }

    @GetMapping("/{id}")
    public ResponseEntity<WorkoutPlanDTO> getPlanById(@PathVariable UUID id) {
        return ResponseEntity.ok(workoutPlanService.getPlanById(id));
    }

    @PostMapping
    public ResponseEntity<WorkoutPlanDTO> createPlan(@RequestBody WorkoutPlanDTO planDTO) {
        return ResponseEntity.ok(workoutPlanService.createPlan(planDTO));
    }

    @PutMapping("/{id}")
    public ResponseEntity<WorkoutPlanDTO> updatePlan(@PathVariable UUID id, @RequestBody WorkoutPlanDTO planDTO) {
        return ResponseEntity.ok(workoutPlanService.updatePlan(id, planDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable UUID id) {
        workoutPlanService.deletePlan(id);
        return ResponseEntity.noContent().build();
    }
}
