package com.bodypilot.backend.service.impl;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class LlmRouterService {

    private final GeminiClient geminiClient;
    private final GroqClient groqClient;

    public boolean isAiReady() {
        return (geminiClient != null && geminiClient.isApiKeyConfigured());
    }

    public String routeChatRequest(String selectedModel, String prompt, String systemInstruction) throws Exception {
        return routeChatRequest(selectedModel, prompt, systemInstruction, false);
    }

    public String routeChatRequest(String selectedModel, String prompt, String systemInstruction, boolean forceJson)
            throws Exception {
        String model = (selectedModel != null && !selectedModel.trim().isEmpty()) ? selectedModel.trim().toLowerCase()
                : "gemini-2.5-flash";

        log.info("🤖 [LLM_ROUTER] Routing request for model (Routed to Gemini 2.5 Flash): '{}', forceJson: {}", model,
                forceJson);

        // Bỏ phần API của Groq, hiện tại chỉ dùng duy nhất Gemini 2.5 Flash
        return callGeminiWithFallback(prompt, systemInstruction, forceJson);

        /*
         * Cấu trúc routing Groq cũ (giữ lại để tích hợp sau):
         * if (model.contains("groq") || model.contains("llama")) {
         * return callGroqWithFallback(selectedModel != null ? selectedModel.trim() :
         * "llama-3.1-8b-instant", prompt, systemInstruction, forceJson);
         * } else {
         * return callGeminiWithFallback(prompt, systemInstruction, forceJson);
         * }
         */
    }

    private String callGroqWithFallback(String modelName, String prompt, String systemInstruction, boolean forceJson)
            throws Exception {
        log.warn("⚠️ [LLM_ROUTER] Groq API hiện đã tạm ngưng. Chuyển hướng sang sử dụng Gemini 2.5 Flash...");
        return callGeminiWithFallback(prompt, systemInstruction, forceJson);

        /*
         * Cấu trúc gọi Groq cũ (giữ lại để tích hợp sau):
         * if (groqClient.isApiKeyConfigured()) {
         * try {
         * return groqClient.callGroq(modelName, prompt, systemInstruction, forceJson);
         * } catch (Exception e) {
         * log.
         * warn("⚠️ [LLM_ROUTER] Groq model '{}' failed: {}. Attempting fallback to Gemini..."
         * , modelName, e.getMessage());
         * if (geminiClient.isApiKeyConfigured()) {
         * return geminiClient.callGemini(prompt, systemInstruction, forceJson);
         * }
         * throw e;
         * }
         * } else if (geminiClient.isApiKeyConfigured()) {
         * log.
         * warn("⚠️ [LLM_ROUTER] Groq API key not configured. Falling back to Gemini..."
         * );
         * return geminiClient.callGemini(prompt, systemInstruction, forceJson);
         * } else {
         * throw new
         * IllegalStateException("Cấu hình API Key AI (Groq & Gemini) chưa sẵn sàng.");
         * }
         */
    }

    private String callGeminiWithFallback(String prompt, String systemInstruction, boolean forceJson) throws Exception {
        if (geminiClient.isApiKeyConfigured()) {
            return geminiClient.callGemini(prompt, systemInstruction, forceJson);
        } else {
            throw new IllegalStateException("Cấu hình API Key Gemini chưa sẵn sàng.");
        }
    }
}
