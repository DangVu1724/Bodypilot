package com.bodypilot.backend.model.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiDietEvaluationSummaryDTO {

    /** Tổng số lần tạo thực đơn AI */
    private Long totalGenerations;

    /** Sai số phần trăm Calo trung bình (MAPE %) */
    private BigDecimal averageMapePercent;

    /** Sai số Calo tuyệt đối trung bình (MAE kcal) */
    private BigDecimal averageMaeCalories;

    /** Số lần hệ thống phải can thiệp Scaling */
    private Long scaledInterventionsCount;

    /** Tỷ lệ can thiệp Scaling (%) */
    private BigDecimal scalingInterventionRatePercent;

    /** Tỷ lệ bảo vệ và thỏa mãn ràng buộc dị ứng (luôn 100%) */
    private BigDecimal constraintSatisfactionRatePercent;

    /** Tổng số lượt dị ứng đã bảo vệ thành công */
    private Long totalAllergiesProtected;

    /** Thời gian phản hồi AI trung bình (ms) */
    private BigDecimal averageExecutionTimeMs;

    /** Danh sách 10 bản ghi đánh giá gần nhất */
    private List<AiDietEvaluationLogDTO> recentLogs;
}
