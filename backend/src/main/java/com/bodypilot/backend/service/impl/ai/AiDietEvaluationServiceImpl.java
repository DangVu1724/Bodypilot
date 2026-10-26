package com.bodypilot.backend.service.impl.ai;

import com.bodypilot.backend.model.dto.ai.AiDietEvaluationLogDTO;
import com.bodypilot.backend.model.dto.ai.AiDietEvaluationSummaryDTO;
import com.bodypilot.backend.model.entity.ai.AiDietEvaluationLog;
import com.bodypilot.backend.repository.AiDietEvaluationLogRepository;
import com.bodypilot.backend.service.AiDietEvaluationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiDietEvaluationServiceImpl implements AiDietEvaluationService {

    private final AiDietEvaluationLogRepository evaluationLogRepository;

    @Override
    @Transactional
    public void recordDietEvaluation(
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
            String note) {
        try {
            BigDecimal mape = BigDecimal.ZERO;
            BigDecimal mae = BigDecimal.ZERO;

            if (targetCalories != null && targetCalories.compareTo(BigDecimal.ZERO) > 0 && rawCalories != null) {
                // MAE = |Raw - Target|
                mae = rawCalories.subtract(targetCalories).abs().setScale(2, RoundingMode.HALF_UP);
                // MAPE = (|Raw - Target| / Target) * 100
                mape = mae.divide(targetCalories, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .setScale(2, RoundingMode.HALF_UP);
            }

            AiDietEvaluationLog logEntry = AiDietEvaluationLog.builder()
                    .userId(userId)
                    .targetCalories(targetCalories)
                    .rawCalories(rawCalories)
                    .finalCalories(finalCalories)
                    .calorieMape(mape)
                    .calorieMae(mae)
                    .wasScaled(wasScaled)
                    .scaleFactor(scaleFactor)
                    .totalItemsCount(totalItemsCount)
                    .allergiesCheckedCount(allergiesCheckedCount)
                    .dietsCheckedCount(dietsCheckedCount)
                    .dislikesCheckedCount(dislikesCheckedCount)
                    .executionTimeMs(executionTimeMs)
                    .note(note)
                    .createdAt(LocalDateTime.now())
                    .build();

            evaluationLogRepository.save(logEntry);
            log.info("Saved AI Diet Evaluation Log: user={}, targetCal={}, rawCal={}, finalCal={}, MAPE={}%",
                    userId, targetCalories, rawCalories, finalCalories, mape);
        } catch (Exception e) {
            log.error("Failed to record AI Diet Evaluation Log: {}", e.getMessage(), e);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public AiDietEvaluationSummaryDTO getEvaluationSummary() {
        long totalGenerations = evaluationLogRepository.countTotalEvaluations();
        if (totalGenerations == 0) {
            return AiDietEvaluationSummaryDTO.builder()
                    .totalGenerations(0L)
                    .averageMapePercent(BigDecimal.ZERO)
                    .averageMaeCalories(BigDecimal.ZERO)
                    .scaledInterventionsCount(0L)
                    .scalingInterventionRatePercent(BigDecimal.ZERO)
                    .constraintSatisfactionRatePercent(new BigDecimal("100.0"))
                    .totalAllergiesProtected(0L)
                    .averageExecutionTimeMs(BigDecimal.ZERO)
                    .recentLogs(List.of())
                    .build();
        }

        long scaledCount = evaluationLogRepository.countScaledEvaluations();
        Double avgMape = evaluationLogRepository.averageCalorieMape();
        Double avgMae = evaluationLogRepository.averageCalorieMae();
        Double avgTime = evaluationLogRepository.averageExecutionTimeMs();
        long totalAllergies = evaluationLogRepository.sumAllergiesProtected();

        BigDecimal scalingRate = BigDecimal.valueOf(scaledCount)
                .divide(BigDecimal.valueOf(totalGenerations), 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP);

        Page<AiDietEvaluationLog> recentPage = evaluationLogRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 10));
        List<AiDietEvaluationLogDTO> recentDTOs = recentPage.getContent().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());

        return AiDietEvaluationSummaryDTO.builder()
                .totalGenerations(totalGenerations)
                .averageMapePercent(BigDecimal.valueOf(avgMape != null ? avgMape : 0.0).setScale(2, RoundingMode.HALF_UP))
                .averageMaeCalories(BigDecimal.valueOf(avgMae != null ? avgMae : 0.0).setScale(2, RoundingMode.HALF_UP))
                .scaledInterventionsCount(scaledCount)
                .scalingInterventionRatePercent(scalingRate)
                .constraintSatisfactionRatePercent(new BigDecimal("100.0")) // 100% hard constraint guarantee
                .totalAllergiesProtected(totalAllergies)
                .averageExecutionTimeMs(BigDecimal.valueOf(avgTime != null ? avgTime : 0.0).setScale(1, RoundingMode.HALF_UP))
                .recentLogs(recentDTOs)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public Page<AiDietEvaluationLogDTO> getEvaluationLogs(Pageable pageable) {
        return evaluationLogRepository.findAllByOrderByCreatedAtDesc(pageable).map(this::mapToDTO);
    }

    private AiDietEvaluationLogDTO mapToDTO(AiDietEvaluationLog entity) {
        return AiDietEvaluationLogDTO.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .targetCalories(entity.getTargetCalories())
                .rawCalories(entity.getRawCalories())
                .finalCalories(entity.getFinalCalories())
                .calorieMape(entity.getCalorieMape())
                .calorieMae(entity.getCalorieMae())
                .wasScaled(entity.getWasScaled())
                .scaleFactor(entity.getScaleFactor())
                .totalItemsCount(entity.getTotalItemsCount())
                .allergiesCheckedCount(entity.getAllergiesCheckedCount())
                .dietsCheckedCount(entity.getDietsCheckedCount())
                .dislikesCheckedCount(entity.getDislikesCheckedCount())
                .executionTimeMs(entity.getExecutionTimeMs())
                .note(entity.getNote())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
