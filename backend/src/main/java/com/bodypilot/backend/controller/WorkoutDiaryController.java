package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutDTO;
import com.bodypilot.backend.model.dto.workout.DailyWorkoutItemDTO;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.service.WorkoutDiaryService;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workout-diary")
@RequiredArgsConstructor
public class WorkoutDiaryController {

    private final WorkoutDiaryService workoutDiaryService;
    private final UserService userService;

    @GetMapping("/day")
    public ResponseEntity<ApiResponse<DailyWorkoutDTO>> getDailyWorkout(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        DailyWorkoutDTO response = workoutDiaryService.getDailyWorkout(user, date);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/range")
    public ResponseEntity<ApiResponse<List<DailyWorkoutDTO>>> getDailyWorkoutRange(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        List<DailyWorkoutDTO> response = workoutDiaryService.getDailyWorkoutRange(user, startDate, endDate);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<DailyWorkoutDTO>> addExercise(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody DailyWorkoutItemDTO itemDTO) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        DailyWorkoutDTO response = workoutDiaryService.addExerciseToDiary(user, date, itemDTO);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/item/{id}")
    public ResponseEntity<ApiResponse<Void>> updateExercise(
            @PathVariable UUID id,
            @RequestBody DailyWorkoutItemDTO itemDTO) {
        workoutDiaryService.updateExerciseInDiary(id, itemDTO);
        return ResponseEntity.ok(ApiResponse.ok("Exercise updated successfully", null));
    }

    @DeleteMapping("/item/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteExercise(@PathVariable UUID id) {
        workoutDiaryService.removeExerciseFromDiary(id);
        return ResponseEntity.ok(ApiResponse.ok("Exercise removed successfully", null));
    }

    @PatchMapping("/item/{id}/status")
    public ResponseEntity<ApiResponse<DailyWorkoutDTO>> updateExerciseStatus(
            @PathVariable UUID id,
            @RequestParam Boolean isCompleted) {
        DailyWorkoutDTO response = workoutDiaryService.updateExerciseStatus(id, isCompleted);
        return ResponseEntity.ok(ApiResponse.ok("Exercise completion status updated successfully", response));
    }

    @PostMapping("/reorder/{dailyWorkoutId}")
    public ResponseEntity<ApiResponse<Void>> reorderItems(
            @PathVariable UUID dailyWorkoutId,
            @RequestBody List<UUID> itemIds) {
        workoutDiaryService.reorderWorkoutItems(dailyWorkoutId, itemIds);
        return ResponseEntity.ok(ApiResponse.ok("Workout items reordered successfully", null));
    }

    @PatchMapping("/note")
    public ResponseEntity<ApiResponse<Void>> updateNote(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam String note) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        workoutDiaryService.updateDailyNote(user, date, note);
        return ResponseEntity.ok(ApiResponse.ok("Note updated successfully", null));
    }

    @PostMapping("/batch")
    public ResponseEntity<ApiResponse<Void>> addBatch(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody List<DailyWorkoutDTO> dailyWorkoutDTOs) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        workoutDiaryService.addMultipleDailyWorkouts(user, dailyWorkoutDTOs);
        return ResponseEntity.ok(ApiResponse.ok("Batch workouts added successfully", null));
    }

    @DeleteMapping("/day")
    public ResponseEntity<ApiResponse<Void>> clearDay(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        workoutDiaryService.clearDay(user, date);
        return ResponseEntity.ok(ApiResponse.ok("Day cleared successfully", null));
    }
}
