package com.bodypilot.backend.service;

import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Pageable;

import com.bodypilot.backend.model.dto.common.PageResponse;
import com.bodypilot.backend.model.dto.workout.ExerciseDTO;
import com.bodypilot.backend.model.dto.workout.WorkoutCategoryDTO;

public interface ExerciseService {
    PageResponse<ExerciseDTO> searchExercises(String name, UUID categoryId, String categoryCode, String bodyPartCode,
            String muscleCode, Pageable pageable);

    ExerciseDTO getExerciseById(UUID id);

    ExerciseDTO createExercise(com.bodypilot.backend.model.dto.workout.ExerciseRequest request);

    ExerciseDTO updateExercise(UUID id, com.bodypilot.backend.model.dto.workout.ExerciseRequest request);

    void deleteExercise(UUID id);

    List<WorkoutCategoryDTO> getAllCategories();

    List<com.bodypilot.backend.model.dto.workout.BodyPartDTO> getAllBodyParts();

    List<com.bodypilot.backend.model.dto.workout.MuscleDTO> getAllMuscles();
}
