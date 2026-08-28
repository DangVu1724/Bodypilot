package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.ai.AiUsageLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AiUsageLogRepository extends JpaRepository<AiUsageLog, UUID> {

    @Query("SELECT COALESCE(SUM(l.totalTokens), 0) FROM AiUsageLog l")
    long sumTotalTokens();

    @Query("SELECT COALESCE(SUM(l.promptTokens), 0) FROM AiUsageLog l")
    long sumPromptTokens();

    @Query("SELECT COALESCE(SUM(l.completionTokens), 0) FROM AiUsageLog l")
    long sumCompletionTokens();

    @Query("SELECT COUNT(l) FROM AiUsageLog l")
    long countTotalAiCalls();

    @Query("SELECT COALESCE(SUM(l.estimatedCostUsd), 0.0) FROM AiUsageLog l")
    double sumTotalCostUsd();
}
