package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.workout.ExerciseDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutSessionDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutSessionExerciseDTO;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;
import com.bodypilot.backend.model.entity.workout.WorkoutSession;
import com.bodypilot.backend.model.entity.workout.WorkoutSessionExercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.WorkoutPlanRepository;
import com.bodypilot.backend.repository.WorkoutSessionExerciseRepository;
import com.bodypilot.backend.repository.WorkoutSessionRepository;
import com.bodypilot.backend.service.WorkoutSessionService;
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
public class WorkoutSessionServiceImpl implements WorkoutSessionService {

    private final WorkoutSessionRepository workoutSessionRepository;
    private final WorkoutPlanRepository workoutPlanRepository;
    private final WorkoutSessionExerciseRepository workoutSessionExerciseRepository;
    private final ExerciseRepository exerciseRepository;

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutSessionDTO> getSessionsByPlanId(UUID planId) {
        log.info("Fetching sessions for plan ID: {}", planId);
        WorkoutPlan plan = workoutPlanRepository.findById(planId)
                .orElseThrow(() -> {
                    log.error("Workout Plan not found with ID: {}", planId);
                    return new RuntimeException("Workout Plan not found with ID: " + planId);
                });
        
        List<WorkoutSession> sessions = workoutSessionRepository.findByPlanOrderByDayNumberAsc(plan);
        log.info("Found {} sessions for plan: {}", sessions.size(), plan.getTitle());
        return sessions.stream()
                .map(session -> mapToDTO(session, planId))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public WorkoutSessionDTO getSessionById(UUID id) {
        WorkoutSession session = workoutSessionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Workout Session not found with ID: " + id));
        return mapToDTO(session);
    }

    @Override
    @Transactional
    public WorkoutSessionDTO createSession(WorkoutSessionDTO sessionDTO) {
        WorkoutPlan plan = workoutPlanRepository.findById(sessionDTO.getPlanId())
                .orElseThrow(() -> new RuntimeException("Workout Plan not found with ID: " + sessionDTO.getPlanId()));

        WorkoutSession session = WorkoutSession.builder()
                .plan(plan)
                .dayNumber(sessionDTO.getDayNumber())
                .name(sessionDTO.getName())
                .build();

        WorkoutSession savedSession = workoutSessionRepository.save(session);

        if (sessionDTO.getExercises() != null && !sessionDTO.getExercises().isEmpty()) {
            List<WorkoutSessionExercise> exercises = sessionDTO.getExercises().stream()
                    .map(eDto -> {
                        Exercise exercise = exerciseRepository.findById(eDto.getExercise().getId())
                                .orElseThrow(() -> new RuntimeException("Exercise not found with ID: " + eDto.getExercise().getId()));
                        return WorkoutSessionExercise.builder()
                                .session(savedSession)
                                .exercise(exercise)
                                .order(eDto.getOrder())
                                .sets(eDto.getSets())
                                .reps(eDto.getReps())
                                .weightKg(eDto.getWeightKg())
                                .restSeconds(eDto.getRestSeconds())
                                .durationMinutes(eDto.getDurationMinutes())
                                .distanceKm(eDto.getDistanceKm())
                                .build();
                    })
                    .collect(Collectors.toList());
            workoutSessionExerciseRepository.saveAll(exercises);
            savedSession.setSessionExercises(exercises);
        }

        return mapToDTO(savedSession);
    }

    @Override
    @Transactional
    public WorkoutSessionDTO updateSession(UUID id, WorkoutSessionDTO sessionDTO) {
        WorkoutSession session = workoutSessionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Workout Session not found with ID: " + id));

        session.setDayNumber(sessionDTO.getDayNumber());
        session.setName(sessionDTO.getName());

        // Simple approach: clear and re-add exercises
        // In a real app, you might want to update existing ones to preserve IDs
        workoutSessionExerciseRepository.deleteAll(session.getSessionExercises());
        session.getSessionExercises().clear();

        if (sessionDTO.getExercises() != null && !sessionDTO.getExercises().isEmpty()) {
            List<WorkoutSessionExercise> exercises = sessionDTO.getExercises().stream()
                    .map(eDto -> {
                        Exercise exercise = exerciseRepository.findById(eDto.getExercise().getId())
                                .orElseThrow(() -> new RuntimeException("Exercise not found with ID: " + eDto.getExercise().getId()));
                        return WorkoutSessionExercise.builder()
                                .session(session)
                                .exercise(exercise)
                                .order(eDto.getOrder())
                                .sets(eDto.getSets())
                                .reps(eDto.getReps())
                                .weightKg(eDto.getWeightKg())
                                .restSeconds(eDto.getRestSeconds())
                                .durationMinutes(eDto.getDurationMinutes())
                                .distanceKm(eDto.getDistanceKm())
                                .build();
                    })
                    .collect(Collectors.toList());
            workoutSessionExerciseRepository.saveAll(exercises);
            session.setSessionExercises(exercises);
        }

        WorkoutSession updatedSession = workoutSessionRepository.save(session);
        return mapToDTO(updatedSession);
    }

    @Override
    @Transactional
    public void deleteSession(UUID id) {
        if (!workoutSessionRepository.existsById(id)) {
            throw new RuntimeException("Workout Session not found with ID: " + id);
        }
        workoutSessionRepository.deleteById(id);
    }

    private WorkoutSessionDTO mapToDTO(WorkoutSession session) {
        return mapToDTO(session, session.getPlan() != null ? session.getPlan().getId() : null);
    }

    private WorkoutSessionDTO mapToDTO(WorkoutSession session, UUID planId) {
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
