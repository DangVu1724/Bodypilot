package com.bodypilot.backend.config;

import java.time.Duration;

import javax.sql.DataSource;

import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.bodypilot.backend.rag.FitnessAiAssistant;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.embedding.AllMiniLmL6V2QuantizedEmbeddingModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.inmemory.InMemoryEmbeddingStore;
import dev.langchain4j.store.embedding.pgvector.PgVectorEmbeddingStore;

@Configuration
public class LangChain4jConfig {

    @Value("${gemini.api.key:demo}")
    private String geminiApiKey;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String geminiModel;

    @Value("${gemini.api.baseUrl:https://generativelanguage.googleapis.com/v1beta/openai/}")
    private String geminiBaseUrl;

    /**
     * Chat Model: Kết nối Google Gemini qua OpenAI-compatible REST Endpoint
     */
    @Bean
    public ChatLanguageModel langChain4jChatModel() {
        String apiKey = (geminiApiKey != null && !geminiApiKey.trim().isEmpty()) ? geminiApiKey.trim() : "demo";
        String model = (geminiModel != null && !geminiModel.trim().isEmpty()) ? geminiModel.trim() : "gemini-1.5-flash";
        String baseUrl = (geminiBaseUrl != null && !geminiBaseUrl.trim().isEmpty()) ? geminiBaseUrl.trim()
                : "https://generativelanguage.googleapis.com/v1beta/openai/";

        return OpenAiChatModel.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .modelName(model)
                .temperature(0.3)
                .timeout(Duration.ofSeconds(60))
                .build();
    }

    /**
     * Embedding Model: Chạy Local trong JVM bằng mô hình Quantized INT8 siêu nhẹ (~23MB)
     */
    @Bean
    public EmbeddingModel langChain4jEmbeddingModel() {
        return new AllMiniLmL6V2QuantizedEmbeddingModel();
    }

    /**
     * Vector Store: Lưu trữ và tìm kiếm vector trong PostgreSQL (pgvector extension)
     */
    @Bean
    public EmbeddingStore<TextSegment> embeddingStore(DataSource dataSource) {
        try {
            return PgVectorEmbeddingStore.datasourceBuilder()
                    .datasource(dataSource)
                    .table("vector_store")
                    .dimension(384)
                    .createTable(true)
                    .dropTableFirst(true)
                    .build();
        } catch (Exception e) {
            LoggerFactory.getLogger(LangChain4jConfig.class)
                    .warn("Không thể khởi tạo PgVectorEmbeddingStore, fallback về InMemoryEmbeddingStore: {}", e.getMessage());
            return new InMemoryEmbeddingStore<>();
        }
    }

    /**
     * AI Service: Fitness Assistant tích hợp RAG
     */
    @Bean
    public FitnessAiAssistant fitnessAiAssistant(ChatLanguageModel langChain4jChatModel) {
        return AiServices.builder(FitnessAiAssistant.class)
                .chatLanguageModel(langChain4jChatModel)
                .build();
    }
}
