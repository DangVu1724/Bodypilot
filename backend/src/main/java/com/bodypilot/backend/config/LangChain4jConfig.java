package com.bodypilot.backend.config;

import com.bodypilot.backend.rag.FitnessAiAssistant;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class LangChain4jConfig {

    @Value("${gemini.api.key:demo}")
    private String geminiApiKey;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String geminiModel;

    @Value("${gemini.api.baseUrl:https://generativelanguage.googleapis.com/v1beta/openai/}")
    private String geminiBaseUrl;

    @Bean
    public ChatLanguageModel langChain4jChatModel() {
        String apiKey = (geminiApiKey != null && !geminiApiKey.trim().isEmpty()) ? geminiApiKey.trim() : "demo";
        String model = (geminiModel != null && !geminiModel.trim().isEmpty()) ? geminiModel.trim() : "gemini-1.5-flash";
        String baseUrl = (geminiBaseUrl != null && !geminiBaseUrl.trim().isEmpty()) ? geminiBaseUrl.trim() : "https://generativelanguage.googleapis.com/v1beta/openai/";

        return OpenAiChatModel.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .modelName(model)
                .temperature(0.3)
                .build();
    }

    @Bean
    public FitnessAiAssistant fitnessAiAssistant(ChatLanguageModel langChain4jChatModel) {
        return AiServices.builder(FitnessAiAssistant.class)
                .chatLanguageModel(langChain4jChatModel)
                .build();
    }
}
