package com.bodypilot.backend.config;

import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.bodypilot.backend.rag.FitnessAiAssistant;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.model.openai.OpenAiEmbeddingModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.store.embedding.EmbeddingStore;

@Configuration
public class LangChain4jConfig {

    @Value("${gemini.api.key:demo}")
    private String geminiApiKey;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String geminiModel;

    @Value("${gemini.embedding.model:gemini-embedding-2}")
    private String geminiEmbeddingModel;

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
                .timeout(Duration.ofSeconds(60))
                .build();
    }

    @Bean
    public EmbeddingModel langChain4jEmbeddingModel() {
        // Model embedding chạy Local trong Java (ONNX), hoàn toàn miễn phí & không giới hạn
        return new dev.langchain4j.model.embedding.AllMiniLmL6V2EmbeddingModel();
    }

    @Bean
    public EmbeddingStore<TextSegment> embeddingStore(javax.sql.DataSource dataSource) {
        try {
            return dev.langchain4j.store.embedding.pgvector.PgVectorEmbeddingStore.datasourceBuilder()
                    .datasource(dataSource)
                    .table("vector_store")
                    .dimension(384)
                    .createTable(true)
                    .dropTableFirst(false)
                    .build();
        } catch (Exception e) {
            org.slf4j.LoggerFactory.getLogger(LangChain4jConfig.class)
                    .warn("Không thể khởi tạo PgVectorEmbeddingStore, fallback về InMemoryEmbeddingStore: {}", e.getMessage());
            return new dev.langchain4j.store.embedding.inmemory.InMemoryEmbeddingStore<>();
        }
    }

    @Bean
    public FitnessAiAssistant fitnessAiAssistant(ChatLanguageModel langChain4jChatModel) {
        return AiServices.builder(FitnessAiAssistant.class)
                .chatLanguageModel(langChain4jChatModel)
                .build();
    }
}

