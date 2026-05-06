package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.ExerciseDTO;
import com.bodypilot.backend.model.dto.PageResponse;
import com.bodypilot.backend.model.dto.WorkoutCategoryDTO;
import com.bodypilot.backend.model.dto.BodyPartDTO;
import com.bodypilot.backend.model.dto.MuscleDTO;
import com.bodypilot.backend.model.entity.Exercise;
import com.bodypilot.backend.model.entity.WorkoutCategory;
import com.bodypilot.backend.model.entity.BodyPart;
import com.bodypilot.backend.model.entity.Muscle;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.WorkoutCategoryRepository;
import com.bodypilot.backend.repository.BodyPartRepository;
import com.bodypilot.backend.repository.MuscleRepository;
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
    private final BodyPartRepository bodyPartRepository;
    private final MuscleRepository muscleRepository;

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutCategoryDTO> getAllCategories() {
        return workoutCategoryRepository.findAll().stream()
                .map(this::mapToCategoryDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<BodyPartDTO> getAllBodyParts() {
        return bodyPartRepository.findAll().stream()
                .map(this::mapToBodyPartDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<MuscleDTO> getAllMuscles() {
        return muscleRepository.findAll().stream()
                .map(this::mapToMuscleDTO)
                .collect(Collectors.toList());
    }

    private WorkoutCategoryDTO mapToCategoryDTO(WorkoutCategory cat) {
        if (cat == null) return null;
        return WorkoutCategoryDTO.builder()
                .id(cat.getId())
                .code(cat.getCode())
                .name(cat.getName())
                .description(cat.getDescription())
                .build();
    }

    private BodyPartDTO mapToBodyPartDTO(BodyPart bodyPart) {
        if (bodyPart == null) return null;
        return BodyPartDTO.builder()
                .id(bodyPart.getId())
                .code(bodyPart.getCode())
                .name(bodyPart.getName())
                .description(bodyPart.getDescription())
                .imageUrl(bodyPart.getImageUrl())
                .build();
    }

    private MuscleDTO mapToMuscleDTO(Muscle muscle) {
        if (muscle == null) return null;
        return MuscleDTO.builder()
                .id(muscle.getId())
                .code(muscle.getCode())
                .name(muscle.getName())
                .description(muscle.getDescription())
                .bodyPartId(muscle.getBodyPart() != null ? muscle.getBodyPart().getId() : null)
                .bodyPartName(muscle.getBodyPart() != null ? muscle.getBodyPart().getName() : null)
                .imageUrl(muscle.getImageUrl())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ExerciseDTO> searchExercises(String name, UUID categoryId, String categoryCode, String bodyPartCode, String muscleCode, Pageable pageable) {
        String catIdStr = categoryId != null ? categoryId.toString() : null;
        Page<Exercise> exercisePage = exerciseRepository.searchExercises(name, catIdStr, categoryCode, bodyPartCode, muscleCode, pageable);
        
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
        
        WorkoutCategoryDTO categoryDTO = mapToCategoryDTO(exercise.getCategory());
        BodyPartDTO bodyPartDTO = mapToBodyPartDTO(exercise.getBodyPart());
        MuscleDTO targetMuscleDTO = mapToMuscleDTO(exercise.getTargetMuscle());
        List<MuscleDTO> secondaryMusclesDTO = exercise.getSecondaryMuscles() != null 
                ? exercise.getSecondaryMuscles().stream().map(this::mapToMuscleDTO).collect(Collectors.toList())
                : null;

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
                .bodyPart(bodyPartDTO)
                .targetMuscle(targetMuscleDTO)
                .secondaryMuscles(secondaryMusclesDTO)
                .build();
    }

    @Override
    @Transactional
    public ExerciseDTO createExercise(com.bodypilot.backend.model.dto.ExerciseRequest request) {
        Exercise exercise = new Exercise();
        updateExerciseFromRequest(exercise, request);
        Exercise savedExercise = exerciseRepository.save(exercise);
        return mapToDTO(savedExercise);
    }

    @Override
    @Transactional
    public ExerciseDTO updateExercise(UUID id, com.bodypilot.backend.model.dto.ExerciseRequest request) {
        Exercise exercise = exerciseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Exercise not found with ID: " + id));
        updateExerciseFromRequest(exercise, request);
        Exercise savedExercise = exerciseRepository.save(exercise);
        return mapToDTO(savedExercise);
    }

    @Override
    @Transactional
    public void deleteExercise(UUID id) {
        if (!exerciseRepository.existsById(id)) {
            throw new RuntimeException("Exercise not found with ID: " + id);
        }
        exerciseRepository.deleteById(id);
    }

    private void updateExerciseFromRequest(Exercise exercise, com.bodypilot.backend.model.dto.ExerciseRequest request) {
        exercise.setCode(request.getCode());
        exercise.setName(request.getName());
        exercise.setDescription(request.getDescription());
        exercise.setMediaUrl(request.getMediaUrl());
        exercise.setThumbnailUrl(request.getThumbnailUrl());
        if (request.getDifficulty() != null) {
            exercise.setDifficulty(com.bodypilot.backend.model.enums.DifficultyLevel.valueOf(request.getDifficulty()));
        }
        exercise.setMetValue(request.getMetValue());
        exercise.setEquipment(request.getEquipment());
        if (request.getDefaultDuration() != null) {
            exercise.setDefaultDuration(request.getDefaultDuration().doubleValue());
        }
        exercise.setDurationUnit(request.getDurationUnit());

        if (request.getCategoryId() != null) {
            exercise.setCategory(workoutCategoryRepository.findById(request.getCategoryId()).orElse(null));
        } else {
            exercise.setCategory(null);
        }

        if (request.getBodyPartId() != null) {
            exercise.setBodyPart(bodyPartRepository.findById(request.getBodyPartId()).orElse(null));
        } else {
            exercise.setBodyPart(null);
        }

        if (request.getTargetMuscleId() != null) {
            exercise.setTargetMuscle(muscleRepository.findById(request.getTargetMuscleId()).orElse(null));
        } else {
            exercise.setTargetMuscle(null);
        }

        if (request.getSecondaryMuscleIds() != null && !request.getSecondaryMuscleIds().isEmpty()) {
            List<Muscle> secondaryMuscles = muscleRepository.findAllById(request.getSecondaryMuscleIds());
            exercise.setSecondaryMuscles(new java.util.HashSet<>(secondaryMuscles));
        } else {
            exercise.setSecondaryMuscles(null);
        }
    }
}
