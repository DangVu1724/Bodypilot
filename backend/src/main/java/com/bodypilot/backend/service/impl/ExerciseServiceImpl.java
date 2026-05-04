package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.ExerciseDTO;
import com.bodypilot.backend.model.dto.PageResponse;
import com.bodypilot.backend.model.dto.WorkoutCategoryDTO;
import com.bodypilot.backend.model.entity.Exercise;
import com.bodypilot.backend.model.entity.WorkoutCategory;
import com.bodypilot.backend.model.enums.WorkoutType;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.WorkoutCategoryRepository;
import com.bodypilot.backend.service.ExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ExerciseServiceImpl implements ExerciseService {

    private final ExerciseRepository exerciseRepository;
    private final WorkoutCategoryRepository workoutCategoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutCategoryDTO> getAllCategories() {
        return workoutCategoryRepository.findAll().stream()
                .map(this::mapToCategoryDTO)
                .collect(Collectors.toList());
    }

    private WorkoutCategoryDTO mapToCategoryDTO(WorkoutCategory cat) {
        if (cat == null) return null;
        return WorkoutCategoryDTO.builder()
                .id(cat.getId())
                .code(cat.getCode())
                .name(cat.getName())
                .description(cat.getDescription())
                .workoutType(cat.getWorkoutType())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ExerciseDTO> searchExercises(String name, UUID categoryId, String categoryCode, WorkoutType workoutType, Pageable pageable) {
        String catIdStr = categoryId != null ? categoryId.toString() : null;
        String typeStr = workoutType != null ? workoutType.name() : null;
        Page<Exercise> exercisePage = exerciseRepository.searchExercises(name, catIdStr, categoryCode, typeStr, pageable);
        
        List<ExerciseDTO> dtoList = exercisePage.getContent().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
                
        return PageResponse.fromPage(exercisePage, dtoList);
    }

    @Override
    @Transactional(readOnly = true)
    public ExerciseDTO getExerciseById(UUID id) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Exercise not found with ID: " + id));
        return mapToDTO(exercise);
    }

    private ExerciseDTO mapToDTO(Exercise exercise) {
        if (exercise == null) return null;
        
        WorkoutCategoryDTO categoryDTO = null;
        if (exercise.getCategory() != null) {
            categoryDTO = mapToCategoryDTO(exercise.getCategory());
        }

        return ExerciseDTO.builder()
                .id(exercise.getId())
                .code(exercise.getCode())
                .name(exercise.getName())
                .description(exercise.getDescription())
                .mediaUrl(exercise.getMediaUrl())
                .thumbnailUrl(exercise.getThumbnailUrl())
                .difficulty(exercise.getDifficulty())
                .metValue(exercise.getMetValue())
                .equipment(exercise.getEquipment())
                .category(categoryDTO)
                .build();
    }
}
