package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.ai.AiDietEvaluationLogDTO;
import com.bodypilot.backend.model.dto.ai.AiDietEvaluationSummaryDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.UUID;

public interface AiDietEvaluationService {

    void recordDietEvaluation(
            UUID userId,
            BigDecimal targetCalories,
            BigDecimal rawCalories,
            BigDecimal finalCalories,
            boolean wasScaled,
            BigDecimal scaleFactor,
            int totalItemsCount,
            int allergiesCheckedCount,
            int dietsCheckedCount,
            int dislikesCheckedCount,
            long executionTimeMs,
            String note
    );

    AiDietEvaluationSummaryDTO getEvaluationSummary();

    Page<AiDietEvaluationLogDTO> getEvaluationLogs(Pageable pageable);
}
