package com.bodypilot.backend.rag;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;

import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.AllMiniLmL6V2EmbeddingModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.output.Response;
import dev.langchain4j.store.embedding.EmbeddingMatch;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.inmemory.InMemoryEmbeddingStore;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class VectorRagService {

    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;

    private EmbeddingModel embeddingModel;
    private final EmbeddingStore<TextSegment> embeddingStore = new InMemoryEmbeddingStore<>();
    private boolean isIndexed = false;
    private boolean initFailed = false;

    private synchronized EmbeddingModel getEmbeddingModel() {
        if (embeddingModel == null && !initFailed) {
            try {
                log.info("[VECTOR_RAG] Initializing AllMiniLmL6V2EmbeddingModel for Vector RAG...");
                embeddingModel = new AllMiniLmL6V2EmbeddingModel();
            } catch (Throwable e) {
                initFailed = true;
                log.error(
                        "[VECTOR_RAG_ERROR] Failed to initialize AllMiniLmL6V2EmbeddingModel (ONNX native library/memory error): {}",
                        e.getMessage(), e);
            }
        }
        return embeddingModel;
    }

    public boolean isIndexed() {
        return isIndexed;
    }

    @EventListener(ApplicationReadyEvent.class)
    @Transactional(readOnly = true)
    public synchronized void indexDatabaseOnStartup() {
        if (isIndexed || initFailed)
            return;

        EmbeddingModel model = getEmbeddingModel();
        if (model == null) {
            log.warn("[VECTOR_RAG_WARN] EmbeddingModel is unavailable; skipping vector database indexing.");
            return;
        }

        long startTime = System.currentTimeMillis();
        log.info("[VECTOR_RAG_START] Dang tu dong Batch Index du lieu Mon an & Bai tap vao Vector Store...");

        try {
            // 1. Chuyển đổi dữ liệu Món ăn song song (Parallel Stream)
            List<Food> foods = foodRepository.findAllWithRelations();
            List<TextSegment> foodSegments = foods.parallelStream().map(f -> {
                String text = String.format(
                        "Món ăn / Dinh dưỡng: %s. Calo/100g: %s kcal. Protein: %sg, Carbs: %sg, Fat: %sg. %s",
                        f.getName(),
                        f.getCaloriesPer100g() != null ? f.getCaloriesPer100g() : "0",
                        f.getProteinPer100g() != null ? f.getProteinPer100g() : "0",
                        f.getCarbsPer100g() != null ? f.getCarbsPer100g() : "0",
                        f.getFatPer100g() != null ? f.getFatPer100g() : "0",
                        f.getDescription() != null ? f.getDescription() : "");
                return TextSegment.from(text);
            }).collect(Collectors.toList());

            int batchSize = 500;

            if (!foodSegments.isEmpty()) {
                for (int i = 0; i < foodSegments.size(); i += batchSize) {
                    List<TextSegment> batch = foodSegments.subList(i, Math.min(i + batchSize, foodSegments.size()));
                    Response<List<Embedding>> response = model.embedAll(batch);
                    embeddingStore.addAll(response.content(), batch);
                }
            }

            // 2. Chuyển đổi dữ liệu Bài tập song song (Parallel Stream)
            List<Exercise> exercises = exerciseRepository.findAllWithRelations();
            List<TextSegment> exerciseSegments = exercises.parallelStream().map(ex -> {
                String text = String.format(
                        "Bài tập thể hình / Fitness: %s. Danh mục: %s. Vùng cơ thể: %s. Nhóm cơ: %s. Mô tả: %s",
                        ex.getName(),
                        ex.getCategory() != null ? ex.getCategory().getName() : "Fitness",
                        ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Chưa rõ",
                        ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Chưa rõ",
                        ex.getDescription() != null ? ex.getDescription() : "");
                return TextSegment.from(text);
            }).collect(Collectors.toList());

            if (!exerciseSegments.isEmpty()) {
                for (int i = 0; i < exerciseSegments.size(); i += batchSize) {
                    List<TextSegment> batch = exerciseSegments.subList(i, Math.min(i + batchSize, exerciseSegments.size()));
                    Response<List<Embedding>> response = model.embedAll(batch);
                    embeddingStore.addAll(response.content(), batch);
                }
            }

            isIndexed = true;
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("[VECTOR_RAG_INDEXED] Hoan thanh Batch Vector Index {} mon an & {} bai tap trong {} ms",
                    foodSegments.size(), exerciseSegments.size(), elapsed);
        } catch (Exception e) {
            log.error("[VECTOR_RAG_ERROR] Loi khi khoi tao Vector RAG Index: {}", e.getMessage(), e);
        }
    }

    public List<String> searchSimilarContext(String query, int maxResults) {
        try {
            if (!isIndexed && !initFailed) {
                indexDatabaseOnStartup();
            }
            EmbeddingModel model = getEmbeddingModel();
            if (model == null) {
                return List.of();
            }
            Embedding queryEmbedding = model.embed(query).content();
            List<EmbeddingMatch<TextSegment>> matches = embeddingStore.findRelevant(queryEmbedding, maxResults, 0.4);

            return matches.stream()
                    .map(match -> match.embedded().text())
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("[VECTOR_RAG_WARN] Loi tra cuu Vector Similarity RAG: {}", e.getMessage());
            return List.of();
        }
    }
}
