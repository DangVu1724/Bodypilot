package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.GeminiService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class AiSuggestionController {

    private final GeminiService geminiService;

    @GetMapping("/{userId}/ai-diet-suggestion")
    public ApiResponse<String> getAiDietSuggestion(
            @PathVariable UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate) {
        if (startDate == null) {
            startDate = LocalDate.now().with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
        }
        String suggestion = geminiService.generateMealSuggestion(userId, startDate);
        return ApiResponse.ok("AI suggestion generated successfully", suggestion);
    }
}
