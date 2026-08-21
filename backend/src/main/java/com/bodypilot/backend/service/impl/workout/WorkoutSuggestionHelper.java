package com.bodypilot.backend.service.impl.workout;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.workout.WorkoutPlan;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Clean Facade for AI Workout Suggestion operations.
 * Delegates responsibilities to:
 * - {@link WorkoutExerciseFilterService}: Exercise filtering & candidate selection.
 * - {@link WorkoutPromptBuilder}: AI workout prompt construction.
 * - {@link WorkoutJsonPostProcessor}: Fail-safe AI workout JSON parsing & food linking.
 * - {@link PresetWorkoutFallbackBuilder}: Medical preset fallback workout plan generation.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WorkoutSuggestionHelper {

    private final WorkoutExerciseFilterService exerciseFilterService;
    private final WorkoutPromptBuilder promptBuilder;
    private final WorkoutJsonPostProcessor jsonPostProcessor;
    private final PresetWorkoutFallbackBuilder presetFallbackBuilder;

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType, String focusBodyPart) {
        return exerciseFilterService.getBalancedExerciseCandidates(userId, goalType, focusBodyPart);
    }

    public List<ExerciseCandidate> getBalancedExerciseCandidates(UUID userId, String goalType) {
        return exerciseFilterService.getBalancedExerciseCandidates(userId, goalType);
    }

    public List<Exercise> getFilteredExercises(List<UserInjury> injuries) {
        return exerciseFilterService.getFilteredExercises(injuries);
    }

    public List<Exercise> selectBalancedExercises(List<Exercise> exercises, int limit, String goalType, String focusBodyPart) {
        return exerciseFilterService.selectBalancedExercises(exercises, limit, goalType, focusBodyPart);
    }

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserInjury> injuries, List<ExerciseCandidate> candidates,
            LocalDate startDate, Integer days, String focusBodyPart) {
        return promptBuilder.buildWorkoutPrompt(profile, goal, metric, injuries, candidates, startDate, days, focusBodyPart);
    }

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserInjury> injuries, List<ExerciseCandidate> candidates,
            List<WorkoutPlan> existingPlans, LocalDate startDate, Integer days) {
        return promptBuilder.buildWorkoutPrompt(profile, goal, metric, injuries, candidates, startDate, days, null);
    }

    public String processAndLinkExercises(String rawJson) {
        return jsonPostProcessor.processAndLinkExercises(rawJson);
    }

    public String generatePresetFallbackWorkoutPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            String focusBodyPart, String noteMessage) {
        return presetFallbackBuilder.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, focusBodyPart, noteMessage);
    }

    public String generatePresetFallbackWorkoutPlan(UUID userId, LocalDate startDate, Integer days, String goalType,
            String noteMessage) {
        return presetFallbackBuilder.generatePresetFallbackWorkoutPlan(userId, startDate, days, goalType, noteMessage);
    }

    public String getFallbackWorkoutJson(LocalDate startDate, String message, Integer days) {
        return presetFallbackBuilder.getFallbackWorkoutJson(startDate, message, days);
    }

    public boolean isViolatingInjuries(Exercise e, List<UserInjury> injuries) {
        return exerciseFilterService.isViolatingInjuries(e, injuries);
    }
}
