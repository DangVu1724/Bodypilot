package com.bodypilot.backend.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Component
@Slf4j
public class GeminiClient {

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/}")
    private String apiUrl;

    @Value("${gemini.model:gemini-2.5-flash}")
    private String model;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(60, TimeUnit.SECONDS)
            .readTimeout(300, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build();

    public boolean isApiKeyConfigured() {
        return apiKey != null && !apiKey.trim().isEmpty();
    }

    public String callGemini(String prompt, String systemInstructionText) throws IOException {
        return callGemini(prompt, systemInstructionText, false);
    }

    public String callGemini(String prompt, String systemInstructionText, boolean forceJson) throws IOException {
        String targetModel = (this.model != null && !this.model.trim().isEmpty()) ? this.model.trim() : "gemini-2.5-flash";
        try {
            return executeGeminiCall(targetModel, prompt, systemInstructionText, forceJson);
        } catch (IOException e) {
            log.warn("⚠️ [GeminiClient] Primary model '{}' failed ({}). Retrying with 'gemini-2.0-flash'...", targetModel, e.getMessage());
            try {
                return executeGeminiCall("gemini-2.0-flash", prompt, systemInstructionText, forceJson);
            } catch (IOException ex) {
                log.warn("⚠️ [GeminiClient] Fallback model 'gemini-2.0-flash' failed, retrying with 'gemini-1.5-flash'...");
                return executeGeminiCall("gemini-1.5-flash", prompt, systemInstructionText, forceJson);
            }
        }
    }

    private String executeGeminiCall(String targetModel, String prompt, String systemInstructionText, boolean forceJson) throws IOException {
        log.info("Preparing Gemini request: model={}, apiUrl={}, forceJson={}", targetModel, apiUrl, forceJson);

        // Build Gemini Request Body
        Map<String, Object> requestBodyMap = new HashMap<>();

        // contents
        List<Map<String, Object>> contents = new ArrayList<>();
        Map<String, Object> contentMap = new HashMap<>();
        List<Map<String, String>> parts = new ArrayList<>();
        parts.add(Map.of("text", prompt));
        contentMap.put("parts", parts);
        contents.add(contentMap);
        requestBodyMap.put("contents", contents);

        // systemInstruction
        Map<String, Object> systemInstruction = new HashMap<>();
        List<Map<String, String>> sysParts = new ArrayList<>();
        sysParts.add(Map.of("text", systemInstructionText));
        systemInstruction.put("parts", sysParts);
        requestBodyMap.put("systemInstruction", systemInstruction);

        // generationConfig
        Map<String, Object> genConfig = new HashMap<>();
        genConfig.put("temperature", 0.7);
        if (forceJson) {
            genConfig.put("responseMimeType", "application/json");
        }
        requestBodyMap.put("generationConfig", genConfig);

        String jsonBody = objectMapper.writeValueAsString(requestBodyMap);

        RequestBody body = RequestBody.create(jsonBody, MediaType.get("application/json; charset=utf-8"));

        String requestUrl = apiUrl + targetModel + ":generateContent?key=" + apiKey;
        log.info("Gemini request URL prepared for model {}", targetModel);

        Request request = new Request.Builder()
                .url(requestUrl)
                .post(body)
                .build();

        long start = System.currentTimeMillis();
        log.info("Calling Gemini API...");
        try (Response response = httpClient.newCall(request).execute()) {
            log.info("Gemini responded in {} ms", System.currentTimeMillis() - start);

            String responseBody = response.body() != null ? response.body().string() : "";

            if (!response.isSuccessful()) {
                throw new IOException("Gemini API call failed with code " + response.code() + ". Details: " + responseBody);
            }

            JsonNode rootNode = objectMapper.readTree(responseBody);
            if (rootNode.has("error")) {
                throw new IOException("Gemini API error: " + rootNode.path("error").path("message").asText());
            }

            JsonNode candidates = rootNode.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                if (rootNode.has("promptFeedback")) {
                    throw new IOException("Gemini blocked prompt. Feedback: " + rootNode.path("promptFeedback").toString());
                }
                throw new IOException("Gemini response has no candidates. Full response: " + responseBody);
            }

            JsonNode candidate = candidates.get(0);
            String finishReason = candidate.path("finishReason").asText();
            if (!"STOP".equals(finishReason)) {
                log.warn("Gemini generation finished with reason: {}", finishReason);
            }

            return candidate.path("content").path("parts").get(0)
                    .path("text").asText();
        }
    }
}
