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
public class GroqClient {

    @Value("${groq.api.key:}")
    private String apiKey;

    @Value("${groq.api.url:https://api.groq.com/openai/v1/chat/completions}")
    private String apiUrl;

    @Value("${groq.default-model:llama-3.3-70b-versatile}")
    private String defaultModel;

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

    public String callGroq(String modelName, String prompt, String systemInstruction) throws IOException {
        return callGroq(modelName, prompt, systemInstruction, false);
    }

    public String callGroq(String modelName, String prompt, String systemInstruction, boolean forceJson) throws IOException {
        String targetModel = (modelName != null && !modelName.trim().isEmpty()) ? modelName.trim() : defaultModel;
        log.info("Preparing Groq request: model={}, apiUrl={}, forceJson={}", targetModel, apiUrl, forceJson);

        Map<String, Object> requestBodyMap = new HashMap<>();
        requestBodyMap.put("model", targetModel);
        requestBodyMap.put("temperature", 0.7);

        if (forceJson) {
            requestBodyMap.put("response_format", Map.of("type", "json_object"));
        }

        List<Map<String, String>> messages = new ArrayList<>();
        if (systemInstruction != null && !systemInstruction.trim().isEmpty()) {
            messages.add(Map.of("role", "system", "content", systemInstruction));
        }
        messages.add(Map.of("role", "user", "content", prompt));
        requestBodyMap.put("messages", messages);

        String jsonBody = objectMapper.writeValueAsString(requestBodyMap);
        RequestBody body = RequestBody.create(jsonBody, MediaType.get("application/json; charset=utf-8"));

        Request request = new Request.Builder()
                .url(apiUrl)
                .addHeader("Authorization", "Bearer " + apiKey)
                .addHeader("Content-Type", "application/json")
                .post(body)
                .build();

        long start = System.currentTimeMillis();
        log.info("Calling Groq API for model {}...", targetModel);
        try (Response response = httpClient.newCall(request).execute()) {
            long duration = System.currentTimeMillis() - start;
            log.info("Groq responded in {} ms with status code {}", duration, response.code());

            String responseBody = response.body() != null ? response.body().string() : "";

            if (!response.isSuccessful()) {
                log.error("Groq API error response: {}", responseBody);
                throw new IOException("Groq API call failed with code " + response.code() + ". Details: " + responseBody);
            }

            JsonNode rootNode = objectMapper.readTree(responseBody);
            if (rootNode.has("error")) {
                throw new IOException("Groq API error: " + rootNode.path("error").path("message").asText());
            }

            JsonNode choices = rootNode.path("choices");
            if (!choices.isArray() || choices.isEmpty()) {
                throw new IOException("Groq response has no choices. Full response: " + responseBody);
            }

            JsonNode firstChoice = choices.get(0);
            return firstChoice.path("message").path("content").asText();
        }
    }
}
