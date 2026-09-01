package com.bodypilot.backend.rag;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;

import dev.langchain4j.data.document.Metadata;
import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.output.Response;
import dev.langchain4j.store.embedding.EmbeddingMatch;
import dev.langchain4j.store.embedding.EmbeddingStore;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class VectorRagService {

    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final EmbeddingModel embeddingModel;
    private final EmbeddingStore<TextSegment> embeddingStore;
    private final JdbcTemplate jdbcTemplate;
    private boolean isIndexed = false;

    public boolean isIndexed() {
        return isIndexed;
    }

    private Set<String> getExistingIndexedIds() {
        try {
            List<String> ids = jdbcTemplate.queryForList(
                    "SELECT (metadata->>'id') FROM vector_store WHERE metadata IS NOT NULL AND metadata->>'id' IS NOT NULL",
                    String.class);
            return new HashSet<>(ids);
        } catch (Exception e) {
            log.warn("[VECTOR_RAG] Khong the doc indexed IDs tu vector_store (co the bang chua ton tai): {}",
                    e.getMessage());
            return Collections.emptySet();
        }
    }

    @EventListener(ApplicationReadyEvent.class)
    @Transactional(readOnly = true)
    public synchronized void indexDatabaseOnStartup() {
        if (isIndexed)
            return;

        if (embeddingModel == null) {
            log.warn("[VECTOR_RAG_WARN] EmbeddingModel is unavailable; skipping vector database indexing.");
            return;
        }

        try {
            Set<String> indexedIds = getExistingIndexedIds();

            // 1. Lọc các món ăn chưa có trong Vector Store
            List<Food> allFoods = foodRepository.findAllWithRelations();
            List<Food> newFoods = allFoods.stream()
                    .filter(f -> f.getId() != null && !indexedIds.contains(f.getId().toString()))
                    .collect(Collectors.toList());

            // 2. Lọc các bài tập chưa có trong Vector Store
            List<Exercise> allExercises = exerciseRepository.findAllWithRelations();
            List<Exercise> newExercises = allExercises.stream()
                    .filter(ex -> ex.getId() != null && !indexedIds.contains(ex.getId().toString()))
                    .collect(Collectors.toList());

            if (newFoods.isEmpty() && newExercises.isEmpty()) {
                isIndexed = true;
                log.info("[VECTOR_RAG] Toan bo {} mon an va {} bai tap da ton tai trong Vector Store. Bo qua re-index.",
                        allFoods.size(), allExercises.size());
                return;
            }

            long startTime = System.currentTimeMillis();
            log.info("[VECTOR_RAG_START] Phat hien {} mon an moi va {} bai tap moi. Dang tien hanh Batch Indexing...",
                    newFoods.size(), newExercises.size());

            // Index Món ăn mới
            if (!newFoods.isEmpty()) {
                List<TextSegment> foodSegments = newFoods.parallelStream().map(this::buildFoodSegment)
                        .collect(Collectors.toList());
                batchEmbedAndSave(foodSegments);
            }

            // Index Bài tập mới
            if (!newExercises.isEmpty()) {
                List<TextSegment> exerciseSegments = newExercises.parallelStream().map(this::buildExerciseSegment)
                        .collect(Collectors.toList());
                batchEmbedAndSave(exerciseSegments);
            }

            isIndexed = true;
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("[VECTOR_RAG_INDEXED] Hoan thanh index {} mon an moi & {} bai tap moi trong {} ms",
                    newFoods.size(), newExercises.size(), elapsed);
        } catch (Exception e) {
            log.error("[VECTOR_RAG_ERROR] Loi khi khoi tao Vector RAG Index: {}", e.getMessage(), e);
        }
    }

    private void batchEmbedAndSave(List<TextSegment> segments) {
        if (segments == null || segments.isEmpty())
            return;
        int batchSize = 100;
        for (int i = 0; i < segments.size(); i += batchSize) {
            List<TextSegment> batch = segments.subList(i, Math.min(i + batchSize, segments.size()));
            Response<List<Embedding>> response = embeddingModel.embedAll(batch);
            embeddingStore.addAll(response.content(), batch);
        }
    }

    public TextSegment buildFoodSegment(Food f) {
        String text = String.format(
                "Món ăn / Dinh dưỡng: %s. Calo/100g: %s kcal. Protein: %sg, Carbs: %sg, Fat: %sg. %s",
                f.getName(),
                f.getCaloriesPer100g() != null ? f.getCaloriesPer100g() : "0",
                f.getProteinPer100g() != null ? f.getProteinPer100g() : "0",
                f.getCarbsPer100g() != null ? f.getCarbsPer100g() : "0",
                f.getFatPer100g() != null ? f.getFatPer100g() : "0",
                f.getDescription() != null ? f.getDescription() : "");
        Metadata metadata = new Metadata();
        metadata.put("type", "FOOD");
        metadata.put("id", f.getId() != null ? f.getId().toString() : "");
        metadata.put("name", f.getName() != null ? f.getName() : "");
        metadata.put("caloriesPer100g", f.getCaloriesPer100g() != null ? f.getCaloriesPer100g().toString() : "0");
        metadata.put("proteinPer100g", f.getProteinPer100g() != null ? f.getProteinPer100g().toString() : "0");
        metadata.put("carbsPer100g", f.getCarbsPer100g() != null ? f.getCarbsPer100g().toString() : "0");
        metadata.put("fatPer100g", f.getFatPer100g() != null ? f.getFatPer100g().toString() : "0");
        return TextSegment.from(text, metadata);
    }

    public TextSegment buildExerciseSegment(Exercise ex) {
        String text = String.format(
                "Bài tập thể hình / Fitness: %s. Danh mục: %s. Vùng cơ thể: %s. Nhóm cơ: %s. Mô tả: %s",
                ex.getName(),
                ex.getCategory() != null ? ex.getCategory().getName() : "Fitness",
                ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Chưa rõ",
                ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Chưa rõ",
                ex.getDescription() != null ? ex.getDescription() : "");
        Metadata metadata = new Metadata();
        metadata.put("type", "EXERCISE");
        metadata.put("id", ex.getId() != null ? ex.getId().toString() : "");
        metadata.put("name", ex.getName() != null ? ex.getName() : "");
        metadata.put("category", ex.getCategory() != null ? ex.getCategory().getName() : "Fitness");
        metadata.put("bodyPart", ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Chưa rõ");
        metadata.put("targetMuscle", ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Chưa rõ");
        return TextSegment.from(text, metadata);
    }

    public void indexFood(Food food) {
        if (food == null || embeddingModel == null)
            return;
        try {
            TextSegment segment = buildFoodSegment(food);
            Response<Embedding> response = embeddingModel.embed(segment);
            embeddingStore.add(response.content(), segment);
            log.info("[VECTOR_RAG] Da index mon an moi: {}", food.getName());
        } catch (Exception e) {
            log.error("[VECTOR_RAG] Loi index mon an {}: {}", food.getName(), e.getMessage());
        }
    }

    public void indexExercise(Exercise exercise) {
        if (exercise == null || embeddingModel == null)
            return;
        try {
            TextSegment segment = buildExerciseSegment(exercise);
            Response<Embedding> response = embeddingModel.embed(segment);
            embeddingStore.add(response.content(), segment);
            log.info("[VECTOR_RAG] Da index bai tap moi: {}", exercise.getName());
        } catch (Exception e) {
            log.error("[VECTOR_RAG] Loi index bai tap {}: {}", exercise.getName(), e.getMessage());
        }
    }

    public List<String> searchSimilarContext(String query, int maxResults) {
        try {
            if (!isIndexed) {
                indexDatabaseOnStartup();
            }
            if (embeddingModel == null) {
                return List.of();
            }
            Embedding queryEmbedding = embeddingModel.embed(query).content();
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
