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
import com.bodypilot.backend.model.entity.user.UserCheckInHistory;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.rag.FitnessAiAssistant;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserCheckInHistoryRepository;
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

    private final UserCheckInHistoryRepository userCheckInHistoryRepository;
    private final UserRepository userRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final LlmRouterService llmRouterService;
    private final FitnessAiAssistant fitnessAiAssistant;
    private final com.bodypilot.backend.rag.VectorRagService vectorRagService;

    @Override
    public ChatResponse processChat(UUID userId, ChatRequest request) {
        long startTime = System.currentTimeMillis();
        log.info("💬 [AI_CHAT_START] Xử lý Hybrid RAG Chatbot cho userId={}, selectedModel={}, userQuery='{}'", userId,
                request.getSelectedModel(), request.getUserQuery());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        UserProfile profile = user.getProfile();
        String userName = profile != null && profile.getFullName() != null ? profile.getFullName()
                : "Người dùng BodyPilot";

        // 1. Grounding Context String: Chỉ nạp đầy đủ Hồ sơ / Chỉ số / Dị ứng khi câu
        // hỏi cần tư vấn cá nhân
        String userContext;
        if (requiresPersonalProfile(request.getUserQuery())) {
            UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                    .stream().findFirst().orElse(null);
            UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                    .stream().findFirst().orElse(null);
            List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
            List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);
            UserCheckInHistory latestCheckIn = userCheckInHistoryRepository.findTopByUserIdOrderByCreatedAtDesc(userId)
                    .orElse(null);

            userContext = buildUserContext(userName, activeGoal, latestMetric, allergies, injuries, latestCheckIn);
        } else {
            // Câu hỏi tra cứu kiến thức chung (vd: "100g ức gà bao nhiêu calo?"): chỉ gửi
            // Tên để xưng hô, tiết kiệm tối đa token
            userContext = "Tên người dùng: " + userName + "\n";
        }

        // 2. Hybrid RAG Retrieval Step: Kết hợp SQL Relational Search + Vector
        // Similarity Search
        String retrievedDbContext = retrieveRelevantDatabaseContext(request.getUserQuery());

        String reply;
        try {
            if ("LANGCHAIN4J".equalsIgnoreCase(request.getSelectedModel())) {
                log.info("Xử lý câu hỏi chatbot qua LangChain4j...");
                reply = fitnessAiAssistant.chat(userContext, retrievedDbContext, request.getUserQuery());
            } else {
                // 3. System Instruction với Guardrails + Hybrid RAG Context
                String systemInstruction = buildSystemInstruction(userContext, retrievedDbContext);
                String formattedPrompt = buildPromptWithHistory(request.getHistory(), request.getUserQuery());
                reply = llmRouterService.routeChatRequest(request.getSelectedModel(), formattedPrompt,
                        systemInstruction, false);
            }
        } catch (Exception e) {
            log.error("Lỗi khi tạo phản hồi chatbot RAG: {}", e.getMessage());
            reply = "Xin lỗi bạn, tôi gặp sự cố nhỏ khi kết nối dữ liệu AI. Bạn có thể lặp lại câu hỏi được không?";
        }

        reply = cleanReplyText(reply);

        long elapsedTime = System.currentTimeMillis() - startTime;
        log.info("Hoàn thành trả lời chatbot trong {} ms", elapsedTime);

        return ChatResponse.builder()
                .reply(reply)
                .timestamp(System.currentTimeMillis())
                .build();
    }

    /**
     * Hybrid RAG Retrieval Step: Kết hợp tra cứu SQL Relational + Vector Similarity
     * Search.
     */
    private String retrieveRelevantDatabaseContext(String userQuery) {
        if (userQuery == null || userQuery.trim().isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();

        // PART A: Relational SQL Keyword Search (Lấy số liệu chính xác từng gram /
        // kcal)
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
                log.warn("⚠️ Lỗi tra cứu món ăn RAG với từ khóa '{}': {}", kw, e.getMessage());
            }
            if (matchedFoods.size() >= 5)
                break;
        }

        if (!matchedFoods.isEmpty()) {
            sb.append("\n[DỮ LIỆU SQL TRỰC TIẾP TỪ DATABASE BODYPILOT]:\n");
            for (Food f : matchedFoods.stream().limit(5).collect(Collectors.toList())) {
                sb.append("- Món: ").append(f.getName())
                        .append(" | Calo/100g: ").append(f.getCaloriesPer100g() != null ? f.getCaloriesPer100g() : 0)
                        .append(" kcal")
                        .append(" | Protein: ").append(f.getProteinPer100g() != null ? f.getProteinPer100g() : 0)
                        .append("g")
                        .append(" | Carbs: ").append(f.getCarbsPer100g() != null ? f.getCarbsPer100g() : 0).append("g")
                        .append(" | Fat: ").append(f.getFatPer100g() != null ? f.getFatPer100g() : 0).append("g");

                sb.append("\n");
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
                log.warn("⚠️ Lỗi tra cứu bài tập RAG với từ khóa '{}': {}", kw, e.getMessage());
            }
            if (matchedExercises.size() >= 5)
                break;
        }

        if (!matchedExercises.isEmpty()) {
            sb.append("\n[DỮ LIỆU BÀI TẬP SQL TÌM THẤY TRONG DATABASE]:\n");
            for (Exercise ex : matchedExercises.stream().limit(5).collect(Collectors.toList())) {
                sb.append("- Bài tập: ").append(ex.getName())
                        .append(" | Danh mục: ")
                        .append(ex.getCategory() != null ? ex.getCategory().getName() : "Thể hình")
                        .append(" | Nhóm cơ chính: ")
                        .append(ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Chưa rõ")
                        .append(" | Vùng cơ thể: ")
                        .append(ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Chưa rõ");

                sb.append("\n");
            }
        }

        // PART B: Vector Similarity Search (Chỉ chạy khi Vector Store đã hoàn tất Batch
        // Indexing)
        if (vectorRagService.isIndexed()) {
            try {
                List<String> vectorMatches = vectorRagService.searchSimilarContext(userQuery, 3);
                if (!vectorMatches.isEmpty()) {
                    sb.append("\n[DỮ LIỆU TƯƠNG ĐỒNG NGỮ NGHĨA TỪ VECTOR STORE (LANGCHAIN4J)]:\n");
                    for (String text : vectorMatches) {
                        sb.append("• ").append(text).append("\n");
                    }
                }
            } catch (Exception e) {
                log.warn("Lỗi tra cứu Vector Store RAG: {}", e.getMessage());
            }
        } else {
            log.info(
                    "[RAG_STATUS] Vector Store chưa hoàn tất Indexing, tự động chuyển sang luồng 1 (SQL + Gemini Grounding).");
        }

        return sb.toString();
    }

    private List<String> extractKeywords(String query) {
        if (query == null)
            return List.of();
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

    private String cleanReplyText(String reply) {
        if (reply == null || reply.trim().isEmpty()) {
            return reply;
        }
        String trimmed = reply.trim();

        if (trimmed.startsWith("```")) {
            trimmed = trimmed.replaceAll("^```(?:json)?\\s*", "").replaceAll("\\s*```$", "").trim();
        }

        if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                com.fasterxml.jackson.databind.JsonNode node = mapper.readTree(trimmed);
                if (node.has("response")) {
                    return node.get("response").asText();
                } else if (node.has("reply")) {
                    return node.get("reply").asText();
                } else if (node.has("message")) {
                    return node.get("message").asText();
                } else if (node.has("content")) {
                    return node.get("content").asText();
                } else if (node.has("text")) {
                    return node.get("text").asText();
                }
            } catch (Exception ignored) {
            }
        }
        return trimmed;
    }

    private boolean requiresPersonalProfile(String query) {
        if (query == null || query.trim().isEmpty())
            return false;
        String lower = query.toLowerCase();

        // Kiểm tra các từ khóa thể hiện ý định tư vấn cá nhân / cho bản thân
        return lower.contains("tôi") || lower.contains("toi")
                || lower.contains("mình") || lower.contains("minh")
                || lower.contains("của tôi") || lower.contains("của mình")
                || lower.contains("cho tôi") || lower.contains("cho mình")
                || lower.contains("hôm nay") || lower.contains("hom nay")
                || lower.contains("thực đơn") || lower.contains("thuc don")
                || lower.contains("lịch tập") || lower.contains("lich tap")
                || lower.contains("gợi ý") || lower.contains("goi y")
                || lower.contains("tư vấn") || lower.contains("tu van")
                || lower.contains("phù hợp") || lower.contains("phu hop")
                || lower.contains("mục tiêu") || lower.contains("muc tieu")
                || lower.contains("giảm cân") || lower.contains("giam can")
                || lower.contains("tăng cân") || lower.contains("tang can")
                || lower.contains("tăng cơ") || lower.contains("tang co")
                || lower.contains("bmi") || lower.contains("calo của")
                || lower.contains("dị ứng") || lower.contains("chấn thương")
                || lower.contains("sức khoẻ") || lower.contains("suc khoe");
    }

    private String buildUserContext(String userName, UserGoal goal, UserMetricHistory metric,
            List<UserAllergy> allergies, List<UserInjury> injuries, UserCheckInHistory latestCheckIn) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tên: ").append(userName).append("\n");

        if (metric != null) {
            sb.append("Cân nặng: ").append(metric.getWeight()).append(" kg, ");
            sb.append("Chiều cao: ").append(metric.getHeightCm()).append(" cm, ");
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

        if (latestCheckIn != null) {
            sb.append("[TRẠNG THÁI SỨC KHỎE & CHECK-IN GẦN NHẤT (").append(latestCheckIn.getCheckInDate())
                    .append(")]:\n");
            if (latestCheckIn.getEnergyLevel() != null) {
                sb.append("- Mức năng lượng/thể trạng: ").append(latestCheckIn.getEnergyLevel()).append("\n");
            }
            if (latestCheckIn.getWorkoutState() != null) {
                sb.append("- Trạng thái cơ bắp/tập luyện: ").append(latestCheckIn.getWorkoutState()).append("\n");
            }
            if (latestCheckIn.getHungerLevel() != null) {
                sb.append("- Cảm giác thèm ăn/đói: ").append(latestCheckIn.getHungerLevel()).append("\n");
            }
            if (latestCheckIn.getNotes() != null && !latestCheckIn.getNotes().trim().isEmpty()) {
                sb.append("- Ghi chú mệt mỏi/thể trạng từ người dùng: ").append(latestCheckIn.getNotes()).append("\n");
            }
        }

        return sb.toString();
    }

    private String buildSystemInstruction(String userContext, String retrievedDbContext) {
        return "Bạn là \"BodyPilot AI Coach\" - Trợ lý y tế, dinh dưỡng và huấn luyện viên cá nhân thông minh của ứng dụng BodyPilot.\n\n"
                +
                "[THÔNG TIN THỂ TRẠNG NGƯỜI DÙNG HẠN ĐỊNH]:\n" + userContext + "\n" +
                (retrievedDbContext.isEmpty() ? "" : retrievedDbContext + "\n") +
                "[PHẠM VI HỖ TRỢ CHỈ CHO PHÉP]:\n" +
                "1. Tư vấn thực đơn, calo, dinh dưỡng, vóc dáng và phân bổ Macro (Protein, Fat, Carbs).\n" +
                "2. Hướng dẫn kỹ thuật bài tập, lịch tập thể hình, cardio, giảm mỡ, tăng cơ.\n" +
                "3. Tư vấn an toàn chấn thương thể thao & dị ứng thực phẩm.\n" +
                "4. Giải đáp thắc mắc sử dụng ứng dụng BodyPilot.\n\n" +
                "[QUY TẮC QUAN TRỌNG BẮT BUỘC (GUARDRAILS)]:\n" +
                "1. Bạn CHỈ trả lời các câu hỏi NẰM TRONG phạm vi Dinh dưỡng, Tập luyện & BodyPilot.\n" +
                "2. Nếu có [DỮ LIỆU THỰC ĐƠN / BÀI TẬP TÌM THẤY TRONG DATABASE BODYPILOT], hãy ưu tiên sử dụng thông số thực tế đó để trả lời chính xác cho người dùng.\n"
                +
                "3. Nếu người dùng hỏi chủ đề ngoài lề (như viết code, lập trình, giải toán, phim ảnh, chính trị, thời tiết...), bạn PHẢI TỪ CHỐI LỊCH SỰ theo đúng mẫu:\n"
                +
                "   \"Xin lỗi bạn, tôi là trợ lý AI chuyên biệt về Dinh Dưỡng & Tập Luyện của BodyPilot. Tôi không thể hỗ trợ các thắc mắc ngoài lĩnh vực sức khỏe và thể thao. Bạn có cần tôi hỗ trợ gì về thực đơn hay bài tập hôm nay không?\"\n"
                +
                "4. Trả lời thân thiện, xưng hô \"tôi\" và \"bạn\", ngắn gọn, dễ hiểu và cô đọng (dưới 150 từ), phù hợp đọc trên điện thoại di động.";
    }

    private String buildPromptWithHistory(List<ChatMessageDTO> history, String userQuery) {
        StringBuilder sb = new StringBuilder();

        if (history != null && !history.isEmpty()) {
            // Giữ tối đa 4 tin nhắn gần nhất để tiết kiệm token
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
