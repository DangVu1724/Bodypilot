package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.entity.user.User;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface WorkoutDiaryService {
    DailyWorkoutDTO getDailyWorkout(User user, LocalDate date);
    List<DailyWorkoutDTO> getDailyWorkoutRange(User user, LocalDate startDate, LocalDate endDate);
    DailyWorkoutDTO addExerciseToDiary(User user, LocalDate date, DailyWorkoutItemDTO itemDTO);
    void updateExerciseInDiary(UUID itemId, DailyWorkoutItemDTO itemDTO);
    void removeExerciseFromDiary(UUID itemId);
    DailyWorkoutDTO updateExerciseStatus(UUID itemId, Boolean isCompleted);
    void reorderWorkoutItems(UUID dailyWorkoutId, List<UUID> itemIds);
    void addMultipleDailyWorkouts(User user, List<DailyWorkoutDTO> dailyWorkoutDTOs);
    void updateDailyNote(User user, LocalDate date, String note);
    void clearDay(User user, LocalDate date);
}
