package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.ExerciseDTO;
import com.bodypilot.backend.model.dto.PageResponse;
import com.bodypilot.backend.model.dto.WorkoutCategoryDTO;
import com.bodypilot.backend.model.enums.WorkoutType;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface ExerciseService {
    PageResponse<ExerciseDTO> searchExercises(String name, UUID categoryId, String categoryCode, WorkoutType workoutType, Pageable pageable);
    ExerciseDTO getExerciseById(UUID id);
    List<WorkoutCategoryDTO> getAllCategories();
}
