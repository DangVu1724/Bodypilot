package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.workout.WorkoutSessionDTO;
import com.bodypilot.backend.service.WorkoutSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workout-sessions")
@RequiredArgsConstructor
public class WorkoutSessionController {

    private final WorkoutSessionService workoutSessionService;

    @GetMapping("/plan/{planId}")
    public ResponseEntity<List<WorkoutSessionDTO>> getSessionsByPlanId(@PathVariable UUID planId) {
        return ResponseEntity.ok(workoutSessionService.getSessionsByPlanId(planId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<WorkoutSessionDTO> getSessionById(@PathVariable UUID id) {
        return ResponseEntity.ok(workoutSessionService.getSessionById(id));
    }

    @PostMapping
    public ResponseEntity<WorkoutSessionDTO> createSession(@RequestBody WorkoutSessionDTO sessionDTO) {
        return ResponseEntity.ok(workoutSessionService.createSession(sessionDTO));
    }

    @PutMapping("/{id}")
    public ResponseEntity<WorkoutSessionDTO> updateSession(@PathVariable UUID id, @RequestBody WorkoutSessionDTO sessionDTO) {
        return ResponseEntity.ok(workoutSessionService.updateSession(id, sessionDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSession(@PathVariable UUID id) {
        workoutSessionService.deleteSession(id);
        return ResponseEntity.noContent().build();
    }
}
