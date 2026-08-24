package com.bodypilot.backend.rag;

import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;
import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.AllMiniLmL6V2EmbeddingModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingMatch;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.inmemory.InMemoryEmbeddingStore;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import dev.langchain4j.model.output.Response;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class VectorRagService {

    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;

    private final EmbeddingModel embeddingModel = new AllMiniLmL6V2EmbeddingModel();
    private final EmbeddingStore<TextSegment> embeddingStore = new InMemoryEmbeddingStore<>();
    private boolean isIndexed = false;

    public boolean isIndexed() {
        return isIndexed;
    }

    @EventListener(ApplicationReadyEvent.class)
    @Transactional(readOnly = true)
    public synchronized void indexDatabaseOnStartup() {
        if (isIndexed) return;
        long startTime = System.currentTimeMillis();
        log.info("🧠 [VECTOR_RAG_START] Đang tự động Batch Index dữ liệu Món ăn & Bài tập vào Vector Store...");

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
                        f.getDescription() != null ? f.getDescription() : ""
                );
                return TextSegment.from(text);
            }).collect(Collectors.toList());

            if (!foodSegments.isEmpty()) {
                Response<List<Embedding>> response = embeddingModel.embedAll(foodSegments);
                embeddingStore.addAll(response.content(), foodSegments);
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
                        ex.getDescription() != null ? ex.getDescription() : ""
                );
                return TextSegment.from(text);
            }).collect(Collectors.toList());

            if (!exerciseSegments.isEmpty()) {
                Response<List<Embedding>> response = embeddingModel.embedAll(exerciseSegments);
                embeddingStore.addAll(response.content(), exerciseSegments);
            }

            isIndexed = true;
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("✅ [VECTOR_RAG_INDEXED] Hoàn thành Batch Vector Index {} món ăn & {} bài tập trong {} ms", foodSegments.size(), exerciseSegments.size(), elapsed);
        } catch (Exception e) {
            log.error("❌ Lỗi khi khởi tạo Vector RAG Index: {}", e.getMessage(), e);
        }
    }

    public List<String> searchSimilarContext(String query, int maxResults) {
        try {
            if (!isIndexed) {
                indexDatabaseOnStartup();
            }
            Embedding queryEmbedding = embeddingModel.embed(query).content();
            List<EmbeddingMatch<TextSegment>> matches = embeddingStore.findRelevant(queryEmbedding, maxResults, 0.4);

            return matches.stream()
                    .map(match -> match.embedded().text())
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("⚠️ Lỗi tra cứu Vector Similarity RAG: {}", e.getMessage());
            return List.of();
        }
    }
}
