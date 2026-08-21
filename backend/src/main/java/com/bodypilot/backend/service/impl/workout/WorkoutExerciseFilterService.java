package com.bodypilot.backend.service.impl.workout;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;


@Component
@RequiredArgsConstructor
@Slf4j
public class WorkoutExerciseFilterService {

    private final ExerciseRepository exerciseRepository;
    private final UserInjuryRepository userInjuryRepository;

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType, String focusBodyPart) {
        List<UserInjury> injuries = (userId != null) ? userInjuryRepository.findAllByUserId(userId) : new ArrayList<>();
        List<Exercise> filteredExercises = getFilteredExercises(injuries);
        List<Exercise> limitedExercises = selectBalancedExercises(filteredExercises, 100, goalType, focusBodyPart);

        return limitedExercises.stream()
                .map(e -> new ExerciseCandidate(
                        e.getId(),
                        e.getName(),
                        e.getBodyPart() != null ? e.getBodyPart().getName() : "Không xác định",
                        e.getTargetMuscle() != null ? e.getTargetMuscle().getName() : "Không xác định",
                        e.getDifficulty() != null ? e.getDifficulty().name() : "BEGINNER"))
                .collect(Collectors.toList());
    }

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType) {
        return getBalancedExerciseCandidates(userId, goalType, null);
    }

    public List<Exercise> getFilteredExercises(List<UserInjury> injuries) {
        List<Exercise> exercises = exerciseRepository.findAll();

        if (injuries == null || injuries.isEmpty()) {
            return exercises;
        }

        Set<UUID> restrictedBodyPartIds = new HashSet<>();

        for (UserInjury userInjury : injuries) {
            Injury injury = userInjury.getInjury();
            if (injury != null && injury.getBodyPart() != null) {
                restrictedBodyPartIds.add(injury.getBodyPart().getId());
            }
        }

        return exercises.stream()
                .filter(e -> e.getBodyPart() == null || !restrictedBodyPartIds.contains(e.getBodyPart().getId()))
                .collect(Collectors.toList());
    }

    public List<Exercise> selectBalancedExercises(List<Exercise> exercises, int limit, String goalType,
            String focusBodyPart) {
        if (exercises.size() <= limit) {
            return exercises;
        }

        Random random = new Random();
        Map<Exercise, Double> exerciseScores = new HashMap<>();
        for (Exercise ex : exercises) {
            double score = calculateExerciseScore(ex, goalType, focusBodyPart) + (random.nextDouble() * 15.0);
            exerciseScores.put(ex, score);
        }

        List<Exercise> sortedExercises = new ArrayList<>(exercises);
        sortedExercises.sort((e1, e2) -> Double.compare(exerciseScores.get(e2), exerciseScores.get(e1)));

        List<Exercise> selected = new ArrayList<>();
        Set<UUID> selectedIds = new HashSet<>();

        // Tier 1: Scarce Categories (Cardio, Aerobics, Yoga) -> Include 100% of available exercises
        List<Exercise> scarceExercises = sortedExercises.stream()
                .filter(e -> {
                    if (e.getCategory() == null || e.getCategory().getCode() == null)
                        return false;
                    String catCode = e.getCategory().getCode().toUpperCase();
                    return catCode.equals("CARDIO") || catCode.equals("AEROBIC") || catCode.equals("YOGA");
                })
                .collect(Collectors.toList());

        for (Exercise ex : scarceExercises) {
            if (selected.size() < limit && selectedIds.add(ex.getId())) {
                selected.add(ex);
            }
        }

        // Tier 2: Focus Body Part Exercises
        if (focusBodyPart != null && !focusBodyPart.isBlank() && !"NONE".equalsIgnoreCase(focusBodyPart)
                && !"KHÔNG CÓ".equalsIgnoreCase(focusBodyPart)) {
            String focusUpper = focusBodyPart.toUpperCase();
            List<Exercise> focusExercises = sortedExercises.stream()
                    .filter(e -> !selectedIds.contains(e.getId()))
                    .filter(e -> {
                        boolean matchBody = e.getBodyPart() != null && e.getBodyPart().getName() != null &&
                                (e.getBodyPart().getName().toUpperCase().contains(focusUpper) ||
                                        (e.getBodyPart().getCode() != null
                                                && focusUpper.contains(e.getBodyPart().getCode().toUpperCase())));
                        boolean matchTarget = e.getTargetMuscle() != null && e.getTargetMuscle().getName() != null &&
                                e.getTargetMuscle().getName().toUpperCase().contains(focusUpper);
                        return matchBody || matchTarget;
                    })
                    .collect(Collectors.toList());

            int focusQuota = Math.min(40, focusExercises.size());
            for (int i = 0; i < focusQuota && selected.size() < limit; i++) {
                Exercise ex = focusExercises.get(i);
                if (selectedIds.add(ex.getId())) {
                    selected.add(ex);
                }
            }
        }

        // Tier 3: Goal-driven Category Quotas for remaining slots
        int remainingSlots = limit - selected.size();
        Map<String, List<Exercise>> categoryMap = new HashMap<>();
        for (Exercise ex : sortedExercises) {
            if (!selectedIds.contains(ex.getId())) {
                String catCode = ex.getCategory() != null && ex.getCategory().getCode() != null
                        ? ex.getCategory().getCode().toUpperCase()
                        : "OTHER";
                categoryMap.computeIfAbsent(catCode, k -> new ArrayList<>()).add(ex);
            }
        }

        Map<String, Integer> categoryQuotas = getGoalCategoryQuotas(goalType, remainingSlots);

        for (Map.Entry<String, List<Exercise>> entry : categoryMap.entrySet()) {
            String catCode = entry.getKey();
            List<Exercise> catExs = entry.getValue();

            int quota = categoryQuotas.getOrDefault(catCode, 15);
            int count = 0;
            for (Exercise ex : catExs) {
                if (count >= quota || selected.size() >= limit)
                    break;
                if (selectedIds.add(ex.getId())) {
                    selected.add(ex);
                    count++;
                }
            }
        }

        // Tier 4: Fill remaining slots up to limit (100)
        for (Exercise ex : sortedExercises) {
            if (selected.size() >= limit)
                break;
            if (selectedIds.add(ex.getId())) {
                selected.add(ex);
            }
        }

        return selected;
    }

    private double calculateExerciseScore(Exercise ex, String goalType, String focusBodyPart) {
        double score = 50.0;
        if (ex == null)
            return score;

        if (focusBodyPart != null && !focusBodyPart.isBlank() && !"NONE".equalsIgnoreCase(focusBodyPart)) {
            String focusUpper = focusBodyPart.toUpperCase();
            if (ex.getBodyPart() != null && ex.getBodyPart().getName() != null
                    && ex.getBodyPart().getName().toUpperCase().contains(focusUpper)) {
                score += 40.0;
            }
            if (ex.getTargetMuscle() != null && ex.getTargetMuscle().getName() != null
                    && ex.getTargetMuscle().getName().toUpperCase().contains(focusUpper)) {
                score += 30.0;
            }
        }

        if (goalType != null) {
            String catCode = ex.getCategory() != null && ex.getCategory().getCode() != null
                    ? ex.getCategory().getCode().toUpperCase()
                    : "";
            switch (goalType) {
                case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> {
                    if (catCode.equals("STRENGTH") || catCode.equals("WEIGHTLIFTING"))
                        score += 25.0;
                }
                case "LOSE_0_5KG", "LOSE_1KG" -> {
                    if (catCode.equals("PLYOMETRICS") || catCode.equals("CARDIO") || catCode.equals("AEROBIC"))
                        score += 25.0;
                }
                case "ENDURANCE" -> {
                    if (catCode.equals("PLYOMETRICS") || catCode.equals("STRENGTH"))
                        score += 20.0;
                }
                default -> {
                    if (catCode.equals("STRENGTH") || catCode.equals("STRETCHING"))
                        score += 15.0;
                }
            }
        }

        return score;
    }

    private Map<String, Integer> getGoalCategoryQuotas(String goalType, int remainingSlots) {
        Map<String, Integer> quotas = new HashMap<>();
        if (goalType == null)
            goalType = "MAINTAIN";

        switch (goalType) {
            case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> {
                quotas.put("STRENGTH", (int) (remainingSlots * 0.65));
                quotas.put("WEIGHTLIFTING", (int) (remainingSlots * 0.15));
                quotas.put("STRETCHING", (int) (remainingSlots * 0.12));
                quotas.put("PLYOMETRICS", (int) (remainingSlots * 0.08));
            }
            case "LOSE_0_5KG", "LOSE_1KG" -> {
                quotas.put("STRENGTH", (int) (remainingSlots * 0.50));
                quotas.put("PLYOMETRICS", (int) (remainingSlots * 0.25));
                quotas.put("STRETCHING", (int) (remainingSlots * 0.15));
                quotas.put("WEIGHTLIFTING", (int) (remainingSlots * 0.10));
            }
            case "ENDURANCE" -> {
                quotas.put("STRENGTH", (int) (remainingSlots * 0.45));
                quotas.put("PLYOMETRICS", (int) (remainingSlots * 0.30));
                quotas.put("STRETCHING", (int) (remainingSlots * 0.15));
                quotas.put("WEIGHTLIFTING", (int) (remainingSlots * 0.10));
            }
            default -> {
                quotas.put("STRENGTH", (int) (remainingSlots * 0.55));
                quotas.put("STRETCHING", (int) (remainingSlots * 0.20));
                quotas.put("PLYOMETRICS", (int) (remainingSlots * 0.15));
                quotas.put("WEIGHTLIFTING", (int) (remainingSlots * 0.10));
            }
        }
        return quotas;
    }

    public boolean isViolatingInjuries(Exercise e, List<UserInjury> injuries) {
        if (e == null)
            return true;
        if (injuries == null || injuries.isEmpty())
            return false;
        for (UserInjury userInjury : injuries) {
            Injury injury = userInjury.getInjury();
            if (injury != null && injury.getBodyPart() != null && e.getBodyPart() != null
                    && injury.getBodyPart().getId().equals(e.getBodyPart().getId())) {
                return true;
            }
        }
        return false;
    }
}
