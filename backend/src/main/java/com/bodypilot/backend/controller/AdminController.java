package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.admin.AdminStatsDTO;
import com.bodypilot.backend.model.dto.ai.AiDietEvaluationLogDTO;
import com.bodypilot.backend.model.dto.ai.AiDietEvaluationSummaryDTO;
import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.AdminService;
import com.bodypilot.backend.service.AiDietEvaluationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final AiDietEvaluationService aiDietEvaluationService;

    @GetMapping("/dashboard-stats")
    public ResponseEntity<ApiResponse<AdminStatsDTO>> getDashboardStats() {
        AdminStatsDTO stats = adminService.getDashboardStats();
        return ResponseEntity.ok(ApiResponse.ok("Dashboard stats retrieved successfully", stats));
    }

    @GetMapping("/ai-eval/summary")
    public ResponseEntity<ApiResponse<AiDietEvaluationSummaryDTO>> getAiDietEvaluationSummary() {
        AiDietEvaluationSummaryDTO summary = aiDietEvaluationService.getEvaluationSummary();
        return ResponseEntity.ok(ApiResponse.ok("AI Diet Evaluation Summary retrieved successfully", summary));
    }

    @GetMapping("/ai-eval/logs")
    public ResponseEntity<ApiResponse<Page<AiDietEvaluationLogDTO>>> getAiDietEvaluationLogs(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        Page<AiDietEvaluationLogDTO> logs = aiDietEvaluationService.getEvaluationLogs(pageable);
        return ResponseEntity.ok(ApiResponse.ok("AI Diet Evaluation Logs retrieved successfully", logs));
    }
}
