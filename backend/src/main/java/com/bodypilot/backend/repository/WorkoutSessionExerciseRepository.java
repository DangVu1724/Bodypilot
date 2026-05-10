package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.workout.WorkoutSessionExercise;
import com.bodypilot.backend.model.entity.workout.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface WorkoutSessionExerciseRepository extends JpaRepository<WorkoutSessionExercise, UUID> {
    List<WorkoutSessionExercise> findBySessionOrderByOrderAsc(WorkoutSession session);
}
