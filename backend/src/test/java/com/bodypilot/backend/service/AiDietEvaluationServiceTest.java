package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.ai.AiDietEvaluationSummaryDTO;
import com.bodypilot.backend.model.entity.ai.AiDietEvaluationLog;
import com.bodypilot.backend.repository.AiDietEvaluationLogRepository;
import com.bodypilot.backend.service.impl.ai.AiDietEvaluationServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiDietEvaluationServiceTest {

    @Mock
    private AiDietEvaluationLogRepository evaluationLogRepository;

    @InjectMocks
    private AiDietEvaluationServiceImpl evaluationService;

    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
    }

    @Test
    void recordDietEvaluation_CalculatesMapeAndMaeCorrectly() {
        // Target = 2000, Raw = 2200 -> Diff = 200 (MAE) -> MAPE = (200 / 2000) * 100 = 10%
        BigDecimal target = new BigDecimal("2000.00");
        BigDecimal raw = new BigDecimal("2200.00");
        BigDecimal finalCal = new BigDecimal("2000.00");

        evaluationService.recordDietEvaluation(
                userId, target, raw, finalCal, true, new BigDecimal("0.91"),
                12, 2, 1, 0, 1500L, "Test run"
        );

        ArgumentCaptor<AiDietEvaluationLog> captor = ArgumentCaptor.forClass(AiDietEvaluationLog.class);
        verify(evaluationLogRepository, times(1)).save(captor.capture());

        AiDietEvaluationLog saved = captor.getValue();
        assertNotNull(saved);
        assertEquals(userId, saved.getUserId());
        assertEquals(new BigDecimal("200.00"), saved.getCalorieMae());
        assertEquals(new BigDecimal("10.00"), saved.getCalorieMape());
        assertTrue(saved.getWasScaled());
        assertEquals(12, saved.getTotalItemsCount());
    }

    @Test
    void getEvaluationSummary_ReturnsAccurateMetrics() {
        when(evaluationLogRepository.countTotalEvaluations()).thenReturn(50L);
        when(evaluationLogRepository.countScaledEvaluations()).thenReturn(5L); // 10% scaling rate
        when(evaluationLogRepository.averageCalorieMape()).thenReturn(4.25);
        when(evaluationLogRepository.averageCalorieMae()).thenReturn(85.0);
        when(evaluationLogRepository.averageExecutionTimeMs()).thenReturn(1450.0);
        when(evaluationLogRepository.sumAllergiesProtected()).thenReturn(120L);

        AiDietEvaluationLog sampleLog = AiDietEvaluationLog.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .targetCalories(new BigDecimal("2000"))
                .rawCalories(new BigDecimal("2050"))
                .finalCalories(new BigDecimal("2050"))
                .calorieMape(new BigDecimal("2.50"))
                .calorieMae(new BigDecimal("50.00"))
                .wasScaled(false)
                .scaleFactor(BigDecimal.ONE)
                .createdAt(LocalDateTime.now())
                .build();

        when(evaluationLogRepository.findAllByOrderByCreatedAtDesc(any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(sampleLog)));

        AiDietEvaluationSummaryDTO summary = evaluationService.getEvaluationSummary();

        assertNotNull(summary);
        assertEquals(50L, summary.getTotalGenerations());
        assertEquals(new BigDecimal("4.25"), summary.getAverageMapePercent());
        assertEquals(new BigDecimal("85.00"), summary.getAverageMaeCalories());
        assertEquals(5L, summary.getScaledInterventionsCount());
        assertEquals(new BigDecimal("10.00"), summary.getScalingInterventionRatePercent());
        assertEquals(new BigDecimal("100.0"), summary.getConstraintSatisfactionRatePercent());
        assertEquals(120L, summary.getTotalAllergiesProtected());
        assertEquals(new BigDecimal("1450.0"), summary.getAverageExecutionTimeMs());
        assertEquals(1, summary.getRecentLogs().size());
    }
}
