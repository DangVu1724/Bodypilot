package com.bodypilot.backend.service.impl;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class LlmRouterService {

    private final GeminiClient geminiClient;

    public boolean isAiReady() {
        return (geminiClient != null && geminiClient.isApiKeyConfigured());
    }

    public String routeChatRequest(String selectedModel, String prompt, String systemInstruction) throws Exception {
        return routeChatRequest(selectedModel, prompt, systemInstruction, false);
    }

    public String routeChatRequest(String selectedModel, String prompt, String systemInstruction, boolean forceJson)
            throws Exception {
        if (!isAiReady()) {
            throw new IllegalStateException("Cấu hình API Key Gemini chưa sẵn sàng.");
        }
        return geminiClient.callGemini(prompt, systemInstruction, forceJson);
    }
}

