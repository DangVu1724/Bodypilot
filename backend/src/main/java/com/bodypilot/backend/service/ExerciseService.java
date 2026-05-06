package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.ExerciseDTO;
import com.bodypilot.backend.model.dto.PageResponse;
import com.bodypilot.backend.model.dto.WorkoutCategoryDTO;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface ExerciseService {
    PageResponse<ExerciseDTO> searchExercises(String name, UUID categoryId, String categoryCode, String bodyPartCode, String muscleCode, Pageable pageable);
    ExerciseDTO getExerciseById(UUID id);
    ExerciseDTO createExercise(com.bodypilot.backend.model.dto.ExerciseRequest request);
    ExerciseDTO updateExercise(UUID id, com.bodypilot.backend.model.dto.ExerciseRequest request);
    void deleteExercise(UUID id);
    List<WorkoutCategoryDTO> getAllCategories();
    List<com.bodypilot.backend.model.dto.BodyPartDTO> getAllBodyParts();
    List<com.bodypilot.backend.model.dto.MuscleDTO> getAllMuscles();
}
