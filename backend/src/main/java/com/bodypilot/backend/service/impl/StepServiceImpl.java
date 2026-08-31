package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.step.StepHistoryDTO;
import com.bodypilot.backend.model.dto.step.StepSyncRequest;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserStepHistory;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.repository.UserStepHistoryRepository;
import com.bodypilot.backend.service.StepService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StepServiceImpl implements StepService {

    private final UserRepository userRepository;
    private final UserStepHistoryRepository stepHistoryRepository;

    @Override
    public StepHistoryDTO syncSteps(UUID userId, StepSyncRequest request) {
        LocalDate syncDate = request.getDate() != null ? request.getDate() : LocalDate.now();
        int steps = request.getStepCount() != null ? request.getStepCount() : 0;

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        double calories = (request.getCaloriesBurned() != null && request.getCaloriesBurned() > 0)
                ? request.getCaloriesBurned()
                : steps * 0.04;

        double distance = (request.getDistanceKm() != null && request.getDistanceKm() > 0)
                ? request.getDistanceKm()
                : steps * 0.00075;

        UserStepHistory entity = stepHistoryRepository.findByUserIdAndDate(userId, syncDate)
                .orElseGet(() -> UserStepHistory.builder()
                        .user(user)
                        .date(syncDate)
                        .stepCount(0)
                        .caloriesBurned(0.0)
                        .distanceKm(0.0)
                        .build());

        int currentSteps = entity.getStepCount() != null ? entity.getStepCount() : 0;
        int effectiveSteps = Math.max(currentSteps, steps);

        double effectiveCalories = (request.getCaloriesBurned() != null && request.getCaloriesBurned() > 0)
                ? Math.max(entity.getCaloriesBurned() != null ? entity.getCaloriesBurned() : 0.0, request.getCaloriesBurned())
                : effectiveSteps * 0.04;

        double effectiveDistance = (request.getDistanceKm() != null && request.getDistanceKm() > 0)
                ? Math.max(entity.getDistanceKm() != null ? entity.getDistanceKm() : 0.0, request.getDistanceKm())
                : effectiveSteps * 0.00075;

        entity.setStepCount(effectiveSteps);
        entity.setCaloriesBurned(effectiveCalories);
        entity.setDistanceKm(effectiveDistance);

        UserStepHistory saved = stepHistoryRepository.save(entity);
        log.info("Synced {} steps (effective: {}) for user {} on {}", steps, effectiveSteps, userId, syncDate);

        return mapToDTO(saved);
    }

    @Override
    public StepHistoryDTO getTodaySteps(UUID userId) {
        LocalDate today = LocalDate.now();
        return stepHistoryRepository.findByUserIdAndDate(userId, today)
                .map(this::mapToDTO)
                .orElse(StepHistoryDTO.builder()
                        .date(today)
                        .stepCount(0)
                        .caloriesBurned(0.0)
                        .distanceKm(0.0)
                        .build());
    }

    @Override
    public List<StepHistoryDTO> getStepHistory(UUID userId, LocalDate startDate, LocalDate endDate) {
        LocalDate start = startDate != null ? startDate : LocalDate.now().minusDays(30);
        LocalDate end = endDate != null ? endDate : LocalDate.now();

        return stepHistoryRepository.findAllByUserIdAndDateBetweenOrderByDateDesc(userId, start, end)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private StepHistoryDTO mapToDTO(UserStepHistory entity) {
        return StepHistoryDTO.builder()
                .id(entity.getId())
                .date(entity.getDate())
                .stepCount(entity.getStepCount())
                .caloriesBurned(entity.getCaloriesBurned())
                .distanceKm(entity.getDistanceKm())
                .build();
    }
}
