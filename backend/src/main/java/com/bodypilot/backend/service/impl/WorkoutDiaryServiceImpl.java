package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.entity.workout.DailyWorkout;
import com.bodypilot.backend.model.entity.workout.DailyWorkoutItem;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.repository.DailyWorkoutItemRepository;
import com.bodypilot.backend.repository.DailyWorkoutRepository;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.service.CalorieCalculatorService;
import com.bodypilot.backend.service.WorkoutDiaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WorkoutDiaryServiceImpl implements WorkoutDiaryService {

    private final DailyWorkoutRepository dailyWorkoutRepository;
    private final DailyWorkoutItemRepository dailyWorkoutItemRepository;
    private final ExerciseRepository exerciseRepository;
    private final CalorieCalculatorService calorieCalculatorService;

    @Override
    @Transactional(readOnly = true)
    public DailyWorkoutDTO getDailyWorkout(User user, LocalDate date) {
        DailyWorkout dailyWorkout = dailyWorkoutRepository.findByUserAndDate(user, date)
                .orElseGet(() -> DailyWorkout.builder().user(user).date(date).build());
        return mapToDailyWorkoutDTO(dailyWorkout);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DailyWorkoutDTO> getDailyWorkoutRange(User user, LocalDate startDate, LocalDate endDate) {
        return dailyWorkoutRepository.findByUserAndDateBetweenOrderByDateAsc(user, startDate, endDate)
                .stream()
                .map(this::mapToDailyWorkoutDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public DailyWorkoutDTO addExerciseToDiary(User user, LocalDate date, DailyWorkoutItemDTO itemDTO) {
        DailyWorkout dailyWorkout = dailyWorkoutRepository.findByUserAndDate(user, date)
                .orElseGet(() -> dailyWorkoutRepository.save(DailyWorkout.builder()
                        .user(user)
                        .date(date)
                        .isAiGenerated(itemDTO.getIsCustom() != null && !itemDTO.getIsCustom())
                        .build()));

        DailyWorkoutItem item = new DailyWorkoutItem();
        item.setDailyWorkout(dailyWorkout);
        item.setOrderIndex(itemDTO.getOrderIndex() != null ? itemDTO.getOrderIndex() : dailyWorkout.getWorkoutItems().size());
        item.setIsCompleted(itemDTO.getIsCompleted() != null ? itemDTO.getIsCompleted() : false);
        item.setSetsSnapshot(itemDTO.getSets());
        item.setRepsSnapshot(itemDTO.getReps());
        item.setWeightKgSnapshot(itemDTO.getWeightKg());
        item.setRestSecondsSnapshot(itemDTO.getRestSeconds());
        item.setDurationMinutesSnapshot(itemDTO.getDurationMinutes());
        item.setDistanceKmSnapshot(itemDTO.getDistanceKm());
        item.setNotes(itemDTO.getNotes());

        if (itemDTO.getExerciseId() != null) {
            Exercise exercise = exerciseRepository.findById(itemDTO.getExerciseId())
                    .orElseThrow(() -> new ResourceNotFoundException("Exercise not found"));
            item.setExercise(exercise);
            item.setExerciseNameSnapshot(exercise.getName());
            item.setIsCustom(false);
            
            // Calculate calories snapshot
            double userWeight = 70.0;
            if (user.getProfile() != null && user.getProfile().getWeight() != null) {
                userWeight = user.getProfile().getWeight();
            }
            double met = exercise.getMetValue() != null ? exercise.getMetValue() : 3.0;
            double duration = itemDTO.getDurationMinutes() != null ? itemDTO.getDurationMinutes().doubleValue() : (exercise.getDefaultDuration() != null ? exercise.getDefaultDuration() : 10.0);
            item.setCaloriesBurnedSnapshot(calorieCalculatorService.calculateWorkoutCalories(met, duration, userWeight));
        } else {
            // Custom exercise
            item.setIsCustom(true);
            item.setExerciseNameSnapshot(itemDTO.getExerciseName() != null ? itemDTO.getExerciseName() : "Custom Exercise");
            item.setCaloriesBurnedSnapshot(itemDTO.getCaloriesBurned() != null ? itemDTO.getCaloriesBurned() : 0.0);
        }

        dailyWorkoutItemRepository.save(item);
        dailyWorkout.getWorkoutItems().add(item);
        recalculateDailyWorkoutCalories(dailyWorkout);

        return mapToDailyWorkoutDTO(dailyWorkout);
    }

    @Override
    @Transactional
    public void updateExerciseInDiary(UUID itemId, DailyWorkoutItemDTO itemDTO) {
        DailyWorkoutItem item = dailyWorkoutItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Workout item not found"));

        item.setSetsSnapshot(itemDTO.getSets());
        item.setRepsSnapshot(itemDTO.getReps());
        item.setWeightKgSnapshot(itemDTO.getWeightKg());
        item.setRestSecondsSnapshot(itemDTO.getRestSeconds());
        item.setDurationMinutesSnapshot(itemDTO.getDurationMinutes());
        item.setDistanceKmSnapshot(itemDTO.getDistanceKm());
        item.setNotes(itemDTO.getNotes());
        if (itemDTO.getOrderIndex() != null) {
            item.setOrderIndex(itemDTO.getOrderIndex());
        }

        if (Boolean.TRUE.equals(item.getIsCustom())) {
            item.setExerciseNameSnapshot(itemDTO.getExerciseName());
            item.setCaloriesBurnedSnapshot(itemDTO.getCaloriesBurned() != null ? itemDTO.getCaloriesBurned() : 0.0);
        } else if (item.getExercise() != null) {
            // Recalculate calories snapshot based on updated duration
            User user = item.getDailyWorkout().getUser();
            double userWeight = 70.0;
            if (user.getProfile() != null && user.getProfile().getWeight() != null) {
                userWeight = user.getProfile().getWeight();
            }
            double met = item.getExercise().getMetValue() != null ? item.getExercise().getMetValue() : 3.0;
            double duration = itemDTO.getDurationMinutes() != null ? itemDTO.getDurationMinutes().doubleValue() : (item.getExercise().getDefaultDuration() != null ? item.getExercise().getDefaultDuration() : 10.0);
            item.setCaloriesBurnedSnapshot(calorieCalculatorService.calculateWorkoutCalories(met, duration, userWeight));
        }

        dailyWorkoutItemRepository.save(item);
        recalculateDailyWorkoutCalories(item.getDailyWorkout());
    }

    @Override
    @Transactional
    public void removeExerciseFromDiary(UUID itemId) {
        DailyWorkoutItem item = dailyWorkoutItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Workout item not found"));
        DailyWorkout dailyWorkout = item.getDailyWorkout();
        dailyWorkout.getWorkoutItems().remove(item);
        dailyWorkoutItemRepository.delete(item);
        recalculateDailyWorkoutCalories(dailyWorkout);
    }

    @Override
    @Transactional
    public DailyWorkoutDTO updateExerciseStatus(UUID itemId, Boolean isCompleted) {
        DailyWorkoutItem item = dailyWorkoutItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Workout item not found"));
        item.setIsCompleted(isCompleted);
        dailyWorkoutItemRepository.save(item);

        DailyWorkout dailyWorkout = item.getDailyWorkout();
        recalculateDailyWorkoutCalories(dailyWorkout);
        return mapToDailyWorkoutDTO(dailyWorkout);
    }

    @Override
    @Transactional
    public void reorderWorkoutItems(UUID dailyWorkoutId, List<UUID> itemIds) {
        DailyWorkout dailyWorkout = dailyWorkoutRepository.findById(dailyWorkoutId)
                .orElseThrow(() -> new ResourceNotFoundException("Daily workout not found"));

        List<DailyWorkoutItem> items = dailyWorkout.getWorkoutItems();
        for (int i = 0; i < itemIds.size(); i++) {
            UUID itemId = itemIds.get(i);
            int orderIndex = i;
            items.stream()
                    .filter(item -> item.getId().equals(itemId))
                    .findFirst()
                    .ifPresent(item -> item.setOrderIndex(orderIndex));
        }
        dailyWorkoutItemRepository.saveAll(items);
    }

    @Override
    @Transactional
    public void addMultipleDailyWorkouts(User user, List<DailyWorkoutDTO> dailyWorkoutDTOs) {
        for (DailyWorkoutDTO dayDto : dailyWorkoutDTOs) {
            DailyWorkout dailyWorkout = dailyWorkoutRepository.findByUserAndDate(user, dayDto.getDate())
                    .orElseGet(() -> DailyWorkout.builder()
                            .user(user)
                            .date(dayDto.getDate())
                            .build());

            dailyWorkout.setNote(dayDto.getNote());
            dailyWorkout.setIsAiGenerated(dayDto.getIsAiGenerated());

            // Clear existing workout items if overwriting
            dailyWorkout.getWorkoutItems().clear();
            DailyWorkout savedDay = dailyWorkoutRepository.save(dailyWorkout);

            if (dayDto.getWorkoutItems() != null) {
                double userWeight = 70.0;
                if (user.getProfile() != null && user.getProfile().getWeight() != null) {
                    userWeight = user.getProfile().getWeight();
                }

                for (DailyWorkoutItemDTO itemDto : dayDto.getWorkoutItems()) {
                    DailyWorkoutItem item = new DailyWorkoutItem();
                    item.setDailyWorkout(savedDay);
                    item.setOrderIndex(itemDto.getOrderIndex());
                    item.setIsCompleted(itemDto.getIsCompleted() != null ? itemDto.getIsCompleted() : false);
                    item.setSetsSnapshot(itemDto.getSets());
                    item.setRepsSnapshot(itemDto.getReps());
                    item.setWeightKgSnapshot(itemDto.getWeightKg());
                    item.setRestSecondsSnapshot(itemDto.getRestSeconds());
                    item.setDurationMinutesSnapshot(itemDto.getDurationMinutes());
                    item.setDistanceKmSnapshot(itemDto.getDistanceKm());
                    item.setNotes(itemDto.getNotes());
                    item.setIsCustom(itemDto.getIsCustom());

                    if (itemDto.getExerciseId() != null) {
                        final double finalUserWeight = userWeight;
                        java.util.Optional<Exercise> exerciseOpt = exerciseRepository.findById(itemDto.getExerciseId());
                        if (exerciseOpt.isPresent()) {
                            Exercise exercise = exerciseOpt.get();
                            item.setExercise(exercise);
                            item.setExerciseNameSnapshot(exercise.getName());
                            double met = exercise.getMetValue() != null ? exercise.getMetValue() : 3.0;
                            double duration = itemDto.getDurationMinutes() != null ? itemDto.getDurationMinutes().doubleValue() : (exercise.getDefaultDuration() != null ? exercise.getDefaultDuration() : 10.0);
                            item.setCaloriesBurnedSnapshot(calorieCalculatorService.calculateWorkoutCalories(met, duration, finalUserWeight));
                        } else {
                            item.setExercise(null);
                            item.setExerciseNameSnapshot(itemDto.getExerciseName() != null ? itemDto.getExerciseName() : "Custom Exercise");
                            item.setCaloriesBurnedSnapshot(itemDto.getCaloriesBurned() != null ? itemDto.getCaloriesBurned() : 0.0);
                            item.setIsCustom(true);
                        }
                    } else {
                        item.setExerciseNameSnapshot(itemDto.getExerciseName() != null ? itemDto.getExerciseName() : "Custom Exercise");
                        item.setCaloriesBurnedSnapshot(itemDto.getCaloriesBurned() != null ? itemDto.getCaloriesBurned() : 0.0);
                    }
                    dailyWorkoutItemRepository.save(item);
                    savedDay.getWorkoutItems().add(item);
                }
            }
            recalculateDailyWorkoutCalories(savedDay);
        }
    }

    @Override
    @Transactional
    public void updateDailyNote(User user, LocalDate date, String note) {
        DailyWorkout dailyWorkout = dailyWorkoutRepository.findByUserAndDate(user, date)
                .orElseGet(() -> dailyWorkoutRepository.save(DailyWorkout.builder()
                        .user(user)
                        .date(date)
                        .build()));
        dailyWorkout.setNote(note);
        dailyWorkoutRepository.save(dailyWorkout);
    }

    @Override
    @Transactional
    public void clearDay(User user, LocalDate date) {
        dailyWorkoutRepository.findByUserAndDate(user, date)
                .ifPresent(dailyWorkoutRepository::delete);
    }

    private void recalculateDailyWorkoutCalories(DailyWorkout dailyWorkout) {
        double totalPlanned = 0.0;
        double totalBurned = 0.0;
        boolean allCompleted = !dailyWorkout.getWorkoutItems().isEmpty();

        for (DailyWorkoutItem item : dailyWorkout.getWorkoutItems()) {
            double cal = item.getCaloriesBurnedSnapshot() != null ? item.getCaloriesBurnedSnapshot() : 0.0;
            totalPlanned += cal;
            if (Boolean.TRUE.equals(item.getIsCompleted())) {
                totalBurned += cal;
            } else {
                allCompleted = false;
            }
        }

        dailyWorkout.setTotalCaloriesPlanned(totalPlanned);
        dailyWorkout.setTotalCaloriesBurned(totalBurned);
        dailyWorkout.setIsCompleted(allCompleted);
        dailyWorkoutRepository.save(dailyWorkout);
    }

    private DailyWorkoutDTO mapToDailyWorkoutDTO(DailyWorkout dailyWorkout) {
        return DailyWorkoutDTO.builder()
                .id(dailyWorkout.getId())
                .date(dailyWorkout.getDate())
                .note(dailyWorkout.getNote())
                .isAiGenerated(dailyWorkout.getIsAiGenerated())
                .totalCaloriesPlanned(dailyWorkout.getTotalCaloriesPlanned())
                .totalCaloriesBurned(dailyWorkout.getTotalCaloriesBurned())
                .isCompleted(dailyWorkout.getIsCompleted())
                .workoutItems(dailyWorkout.getWorkoutItems().stream()
                        .map(this::mapToDailyWorkoutItemDTO)
                        .collect(Collectors.toList()))
                .build();
    }

    private DailyWorkoutItemDTO mapToDailyWorkoutItemDTO(DailyWorkoutItem item) {
        return DailyWorkoutItemDTO.builder()
                .id(item.getId())
                .exerciseId(item.getExercise() != null ? item.getExercise().getId() : null)
                .orderIndex(item.getOrderIndex())
                .isCompleted(item.getIsCompleted())
                .exerciseName(item.getExerciseNameSnapshot())
                .sets(item.getSetsSnapshot())
                .reps(item.getRepsSnapshot())
                .weightKg(item.getWeightKgSnapshot())
                .restSeconds(item.getRestSecondsSnapshot())
                .durationMinutes(item.getDurationMinutesSnapshot())
                .distanceKm(item.getDistanceKmSnapshot())
                .caloriesBurned(item.getCaloriesBurnedSnapshot())
                .isCustom(item.getIsCustom())
                .notes(item.getNotes())
                .build();
    }

    @Override
    @Transactional
    public DailyWorkoutDTO copyDailyWorkout(User user, LocalDate fromDate, LocalDate toDate) {
        DailyWorkout sourceWorkout = dailyWorkoutRepository.findByUserAndDate(user, fromDate)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dữ liệu tập luyện ngày: " + fromDate));

        clearDay(user, toDate);

        DailyWorkout targetWorkout = dailyWorkoutRepository.save(DailyWorkout.builder()
                .user(user)
                .date(toDate)
                .note(sourceWorkout.getNote())
                .isAiGenerated(false)
                .build());

        for (DailyWorkoutItem sourceItem : sourceWorkout.getWorkoutItems()) {
            DailyWorkoutItem newItem = new DailyWorkoutItem();
            newItem.setDailyWorkout(targetWorkout);
            newItem.setExercise(sourceItem.getExercise());
            newItem.setOrderIndex(sourceItem.getOrderIndex());
            newItem.setIsCompleted(false);
            newItem.setExerciseNameSnapshot(sourceItem.getExerciseNameSnapshot());
            newItem.setSetsSnapshot(sourceItem.getSetsSnapshot());
            newItem.setRepsSnapshot(sourceItem.getRepsSnapshot());
            newItem.setWeightKgSnapshot(sourceItem.getWeightKgSnapshot());
            newItem.setRestSecondsSnapshot(sourceItem.getRestSecondsSnapshot());
            newItem.setDurationMinutesSnapshot(sourceItem.getDurationMinutesSnapshot());
            newItem.setDistanceKmSnapshot(sourceItem.getDistanceKmSnapshot());
            newItem.setCaloriesBurnedSnapshot(sourceItem.getCaloriesBurnedSnapshot());
            newItem.setIsCustom(sourceItem.getIsCustom());
            newItem.setNotes(sourceItem.getNotes());
            dailyWorkoutItemRepository.save(newItem);
            targetWorkout.getWorkoutItems().add(newItem);
        }

        recalculateDailyWorkoutCalories(targetWorkout);
        return mapToDailyWorkoutDTO(targetWorkout);
    }
}
