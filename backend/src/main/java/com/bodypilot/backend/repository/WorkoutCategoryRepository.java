package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.WorkoutCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface WorkoutCategoryRepository extends JpaRepository<WorkoutCategory, UUID> {
    Optional<WorkoutCategory> findByCode(String code);
}
