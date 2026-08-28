package com.bodypilot.backend.service.impl;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.entity.ai.AiUsageLog;
import com.bodypilot.backend.repository.AiUsageLogRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.extern.slf4j.Slf4j;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

@Component
@Slf4j
public class GeminiClient {

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/}")
    private String apiUrl;

    @Value("${gemini.model:gemini-2.5-flash}")
    private String primaryModel;

    private final AiUsageLogRepository aiUsageLogRepository;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(60, TimeUnit.SECONDS)
            .readTimeout(300, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build();

    GeminiClient(AiUsageLogRepository aiUsageLogRepository) {
        this.aiUsageLogRepository = aiUsageLogRepository;
    }

    public boolean isApiKeyConfigured() {
        return apiKey != null && !apiKey.trim().isEmpty();
    }

    public String callGemini(String prompt, String systemInstructionText) throws IOException {
        return callGemini(prompt, systemInstructionText, false);
    }

    public String callGemini(String prompt, String systemInstructionText, boolean forceJson) throws IOException {
        String mainModel = (primaryModel != null && !primaryModel.trim().isEmpty()) ? primaryModel.trim()
                : "gemini-2.5-flash";
        List<String> modelsToTry = List.of(mainModel, "gemini-2.0-flash-lite");

        IOException lastException = null;
        for (String modelName : modelsToTry) {
            try {
                return executeGeminiCall(modelName, prompt, systemInstructionText, forceJson);
            } catch (IOException e) {
                lastException = e;
                if (isRateLimitError(e)) {
                    throw new IOException(
                            "Gemini API Rate Limit / Quota Exceeded (429). Vui lòng thử lại sau ít phút hoặc đổi API Key Gemini mới.",
                            e);
                }
                log.warn("Gọi model {} thất bại: {}. Đang thử lại với model dự phòng...", modelName, e.getMessage());
            }
        }
        throw lastException;
    }

    private boolean isRateLimitError(IOException e) {
        String msg = e.getMessage();
        return msg != null && (msg.contains("429") || msg.contains("RESOURCE_EXHAUSTED"));
    }

    private String executeGeminiCall(String targetModel, String prompt, String systemInstructionText, boolean forceJson)
            throws IOException {
        Map<String, Object> requestMap = new LinkedHashMap<>();

        if (systemInstructionText != null && !systemInstructionText.trim().isEmpty()) {
            Map<String, Object> systemInstruction = new LinkedHashMap<>();
            systemInstruction.put("parts", List.of(Map.of("text", systemInstructionText)));
            requestMap.put("systemInstruction", systemInstruction);
        }

        List<Map<String, Object>> contents = new ArrayList<>();
        Map<String, Object> contentMap = new LinkedHashMap<>();
        contentMap.put("role", "user");
        contentMap.put("parts", List.of(Map.of("text", prompt)));
        contents.add(contentMap);
        requestMap.put("contents", contents);

        Map<String, Object> generationConfig = new LinkedHashMap<>();
        if (forceJson) {
            generationConfig.put("responseMimeType", "application/json");
        }
        generationConfig.put("temperature", 0.7);
        requestMap.put("generationConfig", generationConfig);

        String jsonBody = objectMapper.writeValueAsString(requestMap);
        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json; charset=utf-8"));
        String requestUrl = apiUrl + targetModel + ":generateContent?key=" + apiKey;

        Request request = new Request.Builder()
                .url(requestUrl)
                .post(body)
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "";

            if (!response.isSuccessful()) {
                throw new IOException(
                        "Gemini API call failed with code " + response.code() + ". Details: " + responseBody);
            }

            JsonNode rootNode = objectMapper.readTree(responseBody);
            if (rootNode.has("error")) {
                throw new IOException("Gemini API error: " + rootNode.path("error").path("message").asText());
            }

            JsonNode candidates = rootNode.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                if (rootNode.has("promptFeedback")) {
                    throw new IOException("Gemini blocked prompt. Feedback: " + rootNode.path("promptFeedback"));
                }
                throw new IOException("Gemini response has no candidates. Full response: " + responseBody);
            }

            recordUsage(rootNode, targetModel, prompt.length());

            JsonNode candidate = candidates.get(0);
            return candidate.path("content").path("parts").get(0).path("text").asText();
        }
    }

    private void recordUsage(JsonNode rootNode, String targetModel, int promptCharLength) {
        if (aiUsageLogRepository == null)
            return;
        try {
            JsonNode usageNode = rootNode.path("usageMetadata");
            int promptTokens = usageNode.path("promptTokenCount").asInt(0);
            int completionTokens = usageNode.path("candidatesTokenCount").asInt(0);
            int totalTokens = usageNode.path("totalTokenCount").asInt(0);

            if (totalTokens == 0) {
                promptTokens = promptCharLength / 4;
                completionTokens = 150;
                totalTokens = promptTokens + completionTokens;
            }

            double estimatedCost = (promptTokens * 0.075 / 1000000.0) + (completionTokens * 0.300 / 1000000.0);

            aiUsageLogRepository.save(AiUsageLog.builder()
                    .featureName("GEMINI_AI")
                    .modelName(targetModel)
                    .promptTokens(promptTokens)
                    .completionTokens(completionTokens)
                    .totalTokens(totalTokens)
                    .estimatedCostUsd(estimatedCost)
                    .build());
        } catch (Exception ignored) {
            // Suppress non-critical logging exception
        }
    }
}
