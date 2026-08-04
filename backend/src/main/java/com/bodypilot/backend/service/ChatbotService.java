package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.chat.ChatRequest;
import com.bodypilot.backend.model.dto.chat.ChatResponse;

import java.util.UUID;

public interface ChatbotService {
    ChatResponse processChat(UUID userId, ChatRequest request);
}
