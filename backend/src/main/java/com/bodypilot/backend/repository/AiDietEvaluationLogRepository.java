package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.ai.AiDietEvaluationLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AiDietEvaluationLogRepository extends JpaRepository<AiDietEvaluationLog, UUID> {

    Page<AiDietEvaluationLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @Query("SELECT COUNT(l) FROM AiDietEvaluationLog l")
    long countTotalEvaluations();

    @Query("SELECT COUNT(l) FROM AiDietEvaluationLog l WHERE l.wasScaled = true")
    long countScaledEvaluations();

    @Query("SELECT COALESCE(AVG(l.calorieMape), 0.0) FROM AiDietEvaluationLog l")
    Double averageCalorieMape();

    @Query("SELECT COALESCE(AVG(l.calorieMae), 0.0) FROM AiDietEvaluationLog l")
    Double averageCalorieMae();

    @Query("SELECT COALESCE(AVG(l.executionTimeMs), 0.0) FROM AiDietEvaluationLog l")
    Double averageExecutionTimeMs();

    @Query("SELECT COALESCE(SUM(l.allergiesCheckedCount), 0) FROM AiDietEvaluationLog l")
    long sumAllergiesProtected();
}
