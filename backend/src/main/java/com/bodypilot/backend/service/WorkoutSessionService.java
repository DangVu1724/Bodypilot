package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.workout.WorkoutSessionDTO;

import java.util.List;
import java.util.UUID;

public interface WorkoutSessionService {
    List<WorkoutSessionDTO> getSessionsByPlanId(UUID planId);
    WorkoutSessionDTO getSessionById(UUID id);
    WorkoutSessionDTO createSession(WorkoutSessionDTO sessionDTO);
    WorkoutSessionDTO updateSession(UUID id, WorkoutSessionDTO sessionDTO);
    void deleteSession(UUID id);
}
