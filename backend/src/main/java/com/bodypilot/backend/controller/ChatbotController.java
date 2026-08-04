package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.chat.ChatRequest;
import com.bodypilot.backend.model.dto.chat.ChatResponse;
import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.ChatbotService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Slf4j
public class ChatbotController {

    private final ChatbotService chatbotService;

    @PostMapping("/{userId}/chat")
    public ApiResponse<ChatResponse> processChat(
            @PathVariable UUID userId,
            @RequestBody ChatRequest request) {
        log.info("Chatbot request received for userId={}", userId);
        ChatResponse response = chatbotService.processChat(userId, request);
        return ApiResponse.ok("Chat response generated successfully", response);
    }
}
