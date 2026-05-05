package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Exercise;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ExerciseRepository extends JpaRepository<Exercise, UUID> {

    @EntityGraph(attributePaths = {"category", "bodyPart", "targetMuscle"})
    @Query("SELECT e FROM Exercise e " +
           "LEFT JOIN e.bodyPart bp " +
           "LEFT JOIN e.targetMuscle tm " +
           "WHERE " +
           "(cast(:name as string) IS NULL OR LOWER(e.name) LIKE LOWER(CONCAT('%', cast(:name as string), '%'))) AND " +
           "(cast(:categoryId as string) IS NULL OR cast(e.category.id as string) = cast(:categoryId as string)) AND " +
           "(cast(:categoryCode as string) IS NULL OR LOWER(e.category.code) = LOWER(cast(:categoryCode as string))) AND " +
           "(cast(:bodyPartCode as string) IS NULL OR LOWER(bp.code) = LOWER(cast(:bodyPartCode as string))) AND " +
           "(cast(:muscleCode as string) IS NULL OR LOWER(tm.code) = LOWER(cast(:muscleCode as string)))")
    Page<Exercise> searchExercises(@Param("name") String name, 
                                   @Param("categoryId") String categoryId, 
                                   @Param("categoryCode") String categoryCode, 
                                   @Param("bodyPartCode") String bodyPartCode,
                                   @Param("muscleCode") String muscleCode,
                                   Pageable pageable);
}
