package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.ExerciseDTO;
import com.bodypilot.backend.model.dto.PageResponse;
import com.bodypilot.backend.model.dto.WorkoutCategoryDTO;
import com.bodypilot.backend.service.ExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseService exerciseService;

    @GetMapping
    public ResponseEntity<PageResponse<ExerciseDTO>> getExercises(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String categoryCode,
            @RequestParam(required = false) String bodyPartCode,
            @RequestParam(required = false) String muscleCode,
            Pageable pageable) {
        
        PageResponse<ExerciseDTO> response = exerciseService.searchExercises(name, categoryId, categoryCode, bodyPartCode, muscleCode, pageable);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ExerciseDTO> getExerciseById(@PathVariable UUID id) {
        return ResponseEntity.ok(exerciseService.getExerciseById(id));
    }

    @GetMapping("/categories")
    public ResponseEntity<List<WorkoutCategoryDTO>> getCategories() {
        return ResponseEntity.ok(exerciseService.getAllCategories());
    }

    @GetMapping("/body-parts")
    public ResponseEntity<List<com.bodypilot.backend.model.dto.BodyPartDTO>> getBodyParts() {
        return ResponseEntity.ok(exerciseService.getAllBodyParts());
    }

    @GetMapping("/muscles")
    public ResponseEntity<List<com.bodypilot.backend.model.dto.MuscleDTO>> getMuscles() {
        return ResponseEntity.ok(exerciseService.getAllMuscles());
    }

    @org.springframework.web.bind.annotation.PostMapping
    public ResponseEntity<ExerciseDTO> createExercise(@org.springframework.web.bind.annotation.RequestBody com.bodypilot.backend.model.dto.ExerciseRequest request) {
        return ResponseEntity.ok(exerciseService.createExercise(request));
    }

    @org.springframework.web.bind.annotation.PutMapping("/{id}")
    public ResponseEntity<ExerciseDTO> updateExercise(@PathVariable UUID id, @org.springframework.web.bind.annotation.RequestBody com.bodypilot.backend.model.dto.ExerciseRequest request) {
        return ResponseEntity.ok(exerciseService.updateExercise(id, request));
    }

    @org.springframework.web.bind.annotation.DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteExercise(@PathVariable UUID id) {
        exerciseService.deleteExercise(id);
        return ResponseEntity.noContent().build();
    }
}
