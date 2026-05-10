package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.workout.ExerciseDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutPlanDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutSessionDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutSessionExerciseDTO;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.entity.workout.WorkoutSession;
import com.bodypilot.backend.model.entity.workout.WorkoutSessionExercise;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.repository.WorkoutPlanRepository;
import com.bodypilot.backend.service.WorkoutPlanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class WorkoutPlanServiceImpl implements WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepository;

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutPlanDTO> getAllPlansFull() {
        log.info("Fetching all workout plans with full details");
        List<WorkoutPlan> plans = workoutPlanRepository.findAll();
        log.info("Found {} plans in database", plans.size());
        return plans.stream()
                .map(this::mapToDTOFull)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutPlanDTO> getAllPlans() {
        return workoutPlanRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutPlanDTO> getPlansByGoal(Goal goal) {
        return workoutPlanRepository.findByGoal(goal).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public WorkoutPlanDTO getPlanById(UUID id) {
        log.info("Fetching workout plan details for ID: {}", id);
        WorkoutPlan plan = workoutPlanRepository.findById(id)
                .orElseThrow(() -> {
                    log.error("Workout Plan not found with ID: {}", id);
                    return new RuntimeException("Workout Plan not found with ID: " + id);
                });
        return mapToDTOFull(plan);
    }

    @Override
    @Transactional
    public WorkoutPlanDTO createPlan(WorkoutPlanDTO planDTO) {
        WorkoutPlan plan = WorkoutPlan.builder()
                .title(planDTO.getTitle())
                .goal(planDTO.getGoal())
                .difficulty(planDTO.getDifficulty())
                .totalDays(planDTO.getTotalDays())
                .thumbnailUrl(planDTO.getThumbnailUrl())
                .isPremium(planDTO.getIsPremium() != null ? planDTO.getIsPremium() : false)
                .build();
        
        WorkoutPlan savedPlan = workoutPlanRepository.save(plan);
        return mapToDTO(savedPlan);
    }

    @Override
    @Transactional
    public WorkoutPlanDTO updatePlan(UUID id, WorkoutPlanDTO planDTO) {
        WorkoutPlan plan = workoutPlanRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Workout Plan not found with ID: " + id));
        
        plan.setTitle(planDTO.getTitle());
        plan.setGoal(planDTO.getGoal());
        plan.setDifficulty(planDTO.getDifficulty());
        plan.setTotalDays(planDTO.getTotalDays());
        plan.setThumbnailUrl(planDTO.getThumbnailUrl());
        plan.setIsPremium(planDTO.getIsPremium() != null ? planDTO.getIsPremium() : false);
        
        WorkoutPlan updatedPlan = workoutPlanRepository.save(plan);
        return mapToDTO(updatedPlan);
    }

    @Override
    @Transactional
    public void deletePlan(UUID id) {
        if (!workoutPlanRepository.existsById(id)) {
            throw new RuntimeException("Workout Plan not found with ID: " + id);
        }
        workoutPlanRepository.deleteById(id);
    }

    private WorkoutPlanDTO mapToDTO(WorkoutPlan plan) {
        return mapToDTOInternal(plan, false);
    }

    private WorkoutPlanDTO mapToDTOFull(WorkoutPlan plan) {
        return mapToDTOInternal(plan, true);
    }

    private WorkoutPlanDTO mapToDTOInternal(WorkoutPlan plan, boolean includeSessions) {
        if (plan == null) return null;
        
        WorkoutPlanDTO.WorkoutPlanDTOBuilder builder = WorkoutPlanDTO.builder()
                .id(plan.getId())
                .title(plan.getTitle())
                .goal(plan.getGoal())
                .difficulty(plan.getDifficulty())
                .totalDays(plan.getTotalDays())
                .thumbnailUrl(plan.getThumbnailUrl())
                .isPremium(plan.getIsPremium());

        if (includeSessions && plan.getSessions() != null) {
            UUID planId = plan.getId();
            builder.sessions(plan.getSessions().stream()
                    .map(session -> mapToSessionDTO(session, planId))
                    .sorted(Comparator.comparing(WorkoutSessionDTO::getDayNumber, Comparator.nullsLast(Comparator.naturalOrder())))
                    .collect(Collectors.toList()));
        }

        return builder.build();
    }

    private WorkoutSessionDTO mapToSessionDTO(WorkoutSession session) {
        return mapToSessionDTO(session, session.getPlan() != null ? session.getPlan().getId() : null);
    }

    private WorkoutSessionDTO mapToSessionDTO(WorkoutSession session, UUID planId) {
        if (session == null) return null;
        
        List<WorkoutSessionExerciseDTO> exerciseDTOs = null;
        if (session.getSessionExercises() != null) {
            exerciseDTOs = session.getSessionExercises().stream()
                    .map(this::mapToExerciseDTO)
                    .sorted(Comparator.comparing(WorkoutSessionExerciseDTO::getOrder, Comparator.nullsLast(Comparator.naturalOrder())))
                    .collect(Collectors.toList());
        }

        return WorkoutSessionDTO.builder()
                .id(session.getId())
                .planId(planId)
                .dayNumber(session.getDayNumber())
                .name(session.getName())
                .exercises(exerciseDTOs)
                .build();
    }

    private WorkoutSessionExerciseDTO mapToExerciseDTO(WorkoutSessionExercise se) {
        if (se == null) return null;

        ExerciseDTO exerciseDTO = null;
        if (se.getExercise() != null) {
            exerciseDTO = ExerciseDTO.builder()
                    .id(se.getExercise().getId())
                    .code(se.getExercise().getCode())
                    .name(se.getExercise().getName())
                    .description(se.getExercise().getDescription())
                    .thumbnailUrl(se.getExercise().getThumbnailUrl())
                    .difficulty(se.getExercise().getDifficulty())
                    .defaultDuration(se.getExercise().getDefaultDuration())
                    .durationUnit(se.getExercise().getDurationUnit())
                    .build();
        }

        return WorkoutSessionExerciseDTO.builder()
                .id(se.getId())
                .exercise(exerciseDTO)
                .order(se.getOrder())
                .sets(se.getSets())
                .reps(se.getReps())
                .weightKg(se.getWeightKg())
                .restSeconds(se.getRestSeconds())
                .durationMinutes(se.getDurationMinutes())
                .distanceKm(se.getDistanceKm())
                .build();
    }
}
