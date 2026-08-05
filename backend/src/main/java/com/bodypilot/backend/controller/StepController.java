package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.model.dto.step.StepHistoryDTO;
import com.bodypilot.backend.model.dto.step.StepSyncRequest;
import com.bodypilot.backend.service.StepService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class StepController {

    private final StepService stepService;

    @PostMapping("/{userId}/steps/sync")
    public ApiResponse<StepHistoryDTO> syncSteps(
            @PathVariable UUID userId,
            @RequestBody StepSyncRequest request) {
        StepHistoryDTO dto = stepService.syncSteps(userId, request);
        return ApiResponse.ok("Step count synced successfully", dto);
    }

    @GetMapping("/{userId}/steps/today")
    public ApiResponse<StepHistoryDTO> getTodaySteps(@PathVariable UUID userId) {
        StepHistoryDTO dto = stepService.getTodaySteps(userId);
        return ApiResponse.ok("Fetched today steps successfully", dto);
    }

    @GetMapping("/{userId}/steps/history")
    public ApiResponse<List<StepHistoryDTO>> getStepHistory(
            @PathVariable UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<StepHistoryDTO> history = stepService.getStepHistory(userId, startDate, endDate);
        return ApiResponse.ok("Fetched step history successfully", history);
    }
}
