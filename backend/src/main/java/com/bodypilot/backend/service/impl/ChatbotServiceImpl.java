package com.bodypilot.backend.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.chat.ChatMessageDTO;
import com.bodypilot.backend.model.dto.chat.ChatRequest;
import com.bodypilot.backend.model.dto.chat.ChatResponse;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.rag.FitnessAiAssistant;
import com.bodypilot.backend.rag.VectorRagService;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserGoalRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.repository.UserMetricHistoryRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.service.ChatbotService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatbotServiceImpl implements ChatbotService {

    private final UserRepository userRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final FitnessAiAssistant fitnessAiAssistant;
    private final VectorRagService vectorRagService;

    @Override
    public ChatResponse processChat(UUID userId, ChatRequest request) {
        long startTime = System.currentTimeMillis();
        log.info("[AI_CHAT_START] Xử lý Hybrid RAG Chatbot cho userId={}, selectedModel={}, userQuery='{}'",
                userId, request.getSelectedModel(), request.getUserQuery());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        UserProfile profile = user.getProfile();
        String userName = profile != null && profile.getFullName() != null ? profile.getFullName()
                : "Người dùng BodyPilot";

        // 1. Nạp ngữ cảnh người dùng: Chỉ nạp đầy đủ khi bắt đầu hội thoại hoặc sau mỗi
        // 4 tin nhắn
        String userContext;
        if (shouldSendFullUserContext(request.getHistory())) {
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);
            List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);

            userContext = buildUserContext(userName, activeGoal, latestMetric, allergies, injuries);
        } else {
            userContext = "Tên người dùng: " + userName + "\n";
        }

        // 2. Hybrid RAG: Kết hợp SQL Relational Search + Vector Semantic Search
        String retrievedDbContext = retrieveRelevantDatabaseContext(request.getUserQuery());

        // 3. Gửi prompt đến LangChain4j FitnessAiAssistant
        String reply;
        try {
            String formattedPrompt = buildPromptWithHistory(request.getHistory(), request.getUserQuery());
            log.info("Xử lý câu hỏi chatbot qua LangChain4j FitnessAiAssistant...");
            reply = fitnessAiAssistant.chat(userContext, retrievedDbContext, formattedPrompt);
        } catch (Exception e) {
            log.error("Lỗi khi tạo phản hồi chatbot RAG qua LangChain4j: {}", e.getMessage(), e);
            reply = "Xin lỗi bạn, tôi gặp sự cố nhỏ khi kết nối dữ liệu AI. Bạn có thể lặp lại câu hỏi được không?";
        }

        reply = (reply != null) ? reply.trim() : "";

        long elapsedTime = System.currentTimeMillis() - startTime;
        log.info("Hoàn thành trả lời chatbot trong {} ms", elapsedTime);

        return ChatResponse.builder()
                .reply(reply)
                .timestamp(System.currentTimeMillis())
                .build();
    }

    /**
     * Hybrid RAG Retrieval: Kết hợp SQL Relational + Vector Similarity Search
     * Đã tối ưu: Dynamic Routing, Khử trùng lặp (Deduplication) và Tinh gọn Token.
     */
    private String retrieveRelevantDatabaseContext(String userQuery) {
        if (userQuery == null || userQuery.trim().isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        Set<String> retrievedNames = new HashSet<>();

        // Nhánh 1: SQL Keyword Search (Lấy tối đa 5 món ăn & 5 bài tập chính xác)
        List<String> keywords = extractKeywords(userQuery);
        Pageable limitFive = PageRequest.of(0, 5);

        Set<Food> matchedFoods = new LinkedHashSet<>();
        for (String kw : keywords) {
            try {
                Page<Food> foods = foodRepository.searchFoods(kw, null, limitFive);
                if (foods.hasContent()) {
                    matchedFoods.addAll(foods.getContent());
                }
            } catch (Exception e) {
                log.warn("Lỗi tra cứu món ăn SQL: {}", e.getMessage());
            }
            if (matchedFoods.size() >= 5) {
                break;
            }
        }

        Set<Exercise> matchedExercises = new LinkedHashSet<>();
        for (String kw : keywords) {
            try {
                Page<Exercise> exercises = exerciseRepository.searchExercises(kw, null, null, null, null, limitFive);
                if (exercises.hasContent()) {
                    matchedExercises.addAll(exercises.getContent());
                }
            } catch (Exception e) {
                log.warn("Lỗi tra cứu bài tập SQL: {}", e.getMessage());
            }
            if (matchedExercises.size() >= 5) {
                break;
            }
        }

        // 1. Tinh gọn định dạng dữ liệu SQL (Compact Text Format)
        if (!matchedFoods.isEmpty()) {
            sb.append("\n[DỮ LIỆU MÓN ĂN TỪ DATABASE BODYPILOT]:\n");
            for (Food f : matchedFoods.stream().limit(5).collect(Collectors.toList())) {
                retrievedNames.add(f.getName().toLowerCase().trim());
                sb.append("• ").append(f.getName())
                        .append(": ").append(f.getCaloriesPer100g() != null ? f.getCaloriesPer100g() : 0)
                        .append(" kcal/100g")
                        .append(" (P: ").append(f.getProteinPer100g() != null ? f.getProteinPer100g() : 0).append("g")
                        .append(", C: ").append(f.getCarbsPer100g() != null ? f.getCarbsPer100g() : 0).append("g")
                        .append(", F: ").append(f.getFatPer100g() != null ? f.getFatPer100g() : 0).append("g)\n");
            }
        }

        if (!matchedExercises.isEmpty()) {
            sb.append("\n[DỮ LIỆU BÀI TẬP TỪ DATABASE BODYPILOT]:\n");
            for (Exercise ex : matchedExercises.stream().limit(5).collect(Collectors.toList())) {
                retrievedNames.add(ex.getName().toLowerCase().trim());
                sb.append("• ").append(ex.getName())
                        .append(" | Nhóm cơ: ")
                        .append(ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Chưa rõ")
                        .append(" | Vùng: ")
                        .append(ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Chưa rõ\n");
            }
        }

        // 2. Dynamic Routing & Deduplication: Chỉ gọi Vector Search khi SQL chưa đủ dữ
        // liệu và lọc bỏ trùng lặp
        boolean needMoreContext = (matchedFoods.size() < 3 && matchedExercises.size() < 2);
        if (needMoreContext && vectorRagService.isIndexed()) {
            try {
                List<String> vectorMatches = vectorRagService.searchSimilarContext(userQuery, 5);
                List<String> uniqueMatches = new ArrayList<>();

                for (String text : vectorMatches) {
                    // Khử trùng lặp: Nếu món/bài tập đã xuất hiện ở SQL thì bỏ qua
                    boolean alreadyExists = retrievedNames.stream().anyMatch(name -> text.toLowerCase().contains(name));
                    if (!alreadyExists) {
                        uniqueMatches.add(text);
                    }
                }

                if (!uniqueMatches.isEmpty()) {
                    sb.append("\n[GỢI Ý TƯƠNG ĐỒNG BỔ SUNG TỪ VECTOR STORE]:\n");
                    for (String text : uniqueMatches) {
                        sb.append("• ").append(text).append("\n");
                    }
                }
            } catch (Exception e) {
                log.warn("Lỗi tra cứu Vector Store RAG: {}", e.getMessage());
            }
        }

        return sb.toString();
    }

    /**
     * Bóc tách từ khóa tìm kiếm SQL (loại bỏ stopwords và tạo n-grams)
     */
    private List<String> extractKeywords(String query) {
        if (query == null) {
            return List.of();
        }
        String lower = query.toLowerCase().replaceAll("[?,.!;:()\\-]", " ");

        Set<String> stopWords = new HashSet<>(Arrays.asList(
                "chứa", "bao", "nhiêu", "nhieu", "calo", "cung", "cấp", "cap", "đạm", "dam",
                "protein", "carbs", "fat", "và", "va", "như", "nhu", "thế", "the", "nào", "nao",
                "là", "la", "gì", "gi", "tốt", "tot", "vào", "buổi", "buoi", "sáng", "sang",
                "trưa", "trua", "tối", "giúp", "giup", "cho", "tôi", "toi", "hỏi", "hoi",
                "bài", "bai", "tập", "tap", "100g", "món", "mon", "ăn", "an", "được", "duoc",
                "không", "khong", "có", "co", "này", "nay", "nên", "nen", "tránh", "tranh", "cách", "cach"));

        List<String> words = Arrays.stream(lower.split("\\s+"))
                .filter(w -> !w.isEmpty() && !stopWords.contains(w) && w.length() >= 2)
                .collect(Collectors.toList());

        List<String> result = new ArrayList<>();
        // 1. Cụm 2 từ (Bigram)
        for (int i = 0; i < words.size() - 1; i++) {
            result.add(words.get(i) + " " + words.get(i + 1));
        }
        // 2. Các từ đơn lẻ
        result.addAll(words);

        return result;
    }


    /**
     * Chỉ gửi full user context ở đầu cuộc hội thoại hoặc định kỳ sau mỗi 4 tin
     * nhắn
     */
    private boolean shouldSendFullUserContext(List<ChatMessageDTO> history) {
        if (history == null || history.isEmpty()) {
            return true;
        }
        return history.size() % 4 == 0;
    }

    /**
     * Xây dựng chuỗi thông tin người dùng
     */
    private String buildUserContext(String userName, UserGoal goal, UserMetricHistory metric,
            List<UserAllergy> allergies, List<UserInjury> injuries) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tên: ").append(userName).append("\n");

        if (metric != null) {
            sb.append("BMI: ").append(metric.getBmi() != null ? String.format("%.1f", metric.getBmi()) : "Chưa rõ")
                    .append(", ");
            sb.append("Target Calo hàng ngày: ")
                    .append(metric.getTargetCalories() != null ? metric.getTargetCalories().intValue() : 2000)
                    .append(" kcal\n");
        }

        if (goal != null) {
            sb.append("Mục tiêu hiện tại: ").append(goal.getType()).append(" (Cân nặng mục tiêu: ")
                    .append(goal.getTargetWeight() != null ? goal.getTargetWeight() + "kg" : "Duy trì").append(")\n");
        }

        if (!allergies.isEmpty()) {
            String allergyList = allergies.stream()
                    .filter(a -> a.getAllergyMaster() != null)
                    .map(a -> a.getAllergyMaster().getName())
                    .collect(Collectors.joining(", "));
            sb.append("Dị ứng thực phẩm: ").append(allergyList).append("\n");
        }

        if (!injuries.isEmpty()) {
            String injuryList = injuries.stream()
                    .filter(i -> i.getInjury() != null)
                    .map(i -> i.getInjury().getName())
                    .collect(Collectors.joining(", "));
            sb.append("Chấn thương hiện tại: ").append(injuryList).append("\n");
        }

        return sb.toString();
    }

    /**
     * Ghép lịch sử hội thoại gần nhất (tối đa 4 tin nhắn) kèm câu hỏi mới
     */
    private String buildPromptWithHistory(List<ChatMessageDTO> history, String userQuery) {
        StringBuilder sb = new StringBuilder();

        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 4);
            sb.append("[TÓM TẮT HỘI THOẠI TRƯỚC ĐÓ]:\n");
            for (int i = start; i < history.size(); i++) {
                ChatMessageDTO msg = history.get(i);
                boolean isUser = "user".equalsIgnoreCase(msg.getRole());
                String content = msg.getContent() != null ? msg.getContent().trim() : "";

                if (!isUser && content.length() > 90) {
                    content = content.substring(0, 90).replaceAll("[\\r\\n]+", " ") + "...";
                }

                sb.append(isUser ? "• Người dùng: " : "• AI: ")
                        .append(content)
                        .append("\n");
            }
            sb.append("\n");
        }

        sb.append("[CÂU HỎI MỚI CỦA NGƯỜI DÙNG]:\n").append(userQuery);
        return sb.toString();
    }
}
