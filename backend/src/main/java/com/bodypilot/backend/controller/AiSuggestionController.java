package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.GeminiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Slf4j
public class AiSuggestionController {

    private final GeminiService geminiService;

    @GetMapping("/{userId}/ai-diet-suggestion")
    public ApiResponse<String> getAiDietSuggestion(
            @PathVariable UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false, defaultValue = "7") Integer days,
            @RequestParam(required = false) String userFeedback) {
        if (startDate == null) {
            startDate = LocalDate.now();
        }
        log.info("Nhận yêu cầu gợi ý thực đơn AI: userId={}, startDate={}, days={}", userId, startDate, days);
        String suggestion = geminiService.generateMealSuggestion(userId, startDate, days, userFeedback);
        return ApiResponse.ok("Tạo gợi ý thực đơn thành công", suggestion);
    }

    @GetMapping("/{userId}/ai-workout-suggestion")
    public ApiResponse<String> getAiWorkoutSuggestion(
            @PathVariable UUID userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false, defaultValue = "7") Integer days,
            @RequestParam(required = false) String focusBodyPart) {
        if (startDate == null) {
            startDate = LocalDate.now();
        }
        log.info("Nhận yêu cầu gợi ý lịch tập AI: userId={}, startDate={}, days={}", userId, startDate, days);
        String suggestion = geminiService.generateWorkoutSuggestion(userId, startDate, days, focusBodyPart);
        return ApiResponse.ok("Tạo gợi ý lịch tập thành công", suggestion);
    }
}

