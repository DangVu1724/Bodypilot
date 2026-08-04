package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.chat.ChatMessageDTO;
import com.bodypilot.backend.model.dto.chat.ChatRequest;
import com.bodypilot.backend.model.dto.chat.ChatResponse;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.ChatbotService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatbotServiceImpl implements ChatbotService {

    private final UserRepository userRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final GeminiClient geminiClient;

    @Override
    public ChatResponse processChat(UUID userId, ChatRequest request) {
        long startTime = System.currentTimeMillis();
        log.info("💬 [AI_CHAT_START] Xử lý câu hỏi chat cho userId={}, userQuery='{}'", userId, request.getUserQuery());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        UserProfile profile = user.getProfile();
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        UserMetricHistory latestMetric = metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().findFirst().orElse(null);

        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        List<UserInjury> injuries = userInjuryRepository.findAllByUserId(userId);

        // Grounding Context String
        String userContext = buildUserContext(profile, activeGoal, latestMetric, allergies, injuries);

        // System Instruction with strict Guardrails
        String systemInstruction = buildSystemInstruction(userContext);

        // Sliding Window Chat History (Keep last 6 messages)
        String formattedPrompt = buildPromptWithHistory(request.getHistory(), request.getUserQuery());

        String reply;
        try {
            if (geminiClient.isApiKeyConfigured()) {
                reply = geminiClient.callGemini(formattedPrompt, systemInstruction, false);
            } else {
                reply = "Xin lỗi bạn, cấu hình kết nối AI hiện tại chưa sẵn sàng. Bạn vui lòng thử lại sau ít phút nhé!";
            }
        } catch (Exception e) {
            log.error("❌ Error generating chatbot response: ", e);
            reply = "Xin lỗi bạn, tôi gặp sự cố nhỏ khi kết nối dữ liệu. Bạn có thể lặp lại câu hỏi về dinh dưỡng hay bài tập được không?";
        }

        reply = cleanReplyText(reply);

        long elapsedTime = System.currentTimeMillis() - startTime;
        log.info("✅ [AI_CHAT_END] Hoàn thành trả lời chat trong {} ms", elapsedTime);

        return ChatResponse.builder()
                .reply(reply)
                .timestamp(System.currentTimeMillis())
                .build();
    }

    private String cleanReplyText(String reply) {
        if (reply == null || reply.trim().isEmpty()) {
            return reply;
        }
        String trimmed = reply.trim();

        // Strip markdown code fences if wrapped in ```json ... ``` or ``` ... ```
        if (trimmed.startsWith("```")) {
            trimmed = trimmed.replaceAll("^```(?:json)?\\s*", "").replaceAll("\\s*```$", "").trim();
        }

        // Check if it's a JSON object starting with { and ending with }
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
                // Not valid JSON or parsing failed, return trimmed text
            }
        }
        return trimmed;
    }

    private String buildUserContext(UserProfile profile, UserGoal goal, UserMetricHistory metric, List<UserAllergy> allergies, List<UserInjury> injuries) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tên: ").append(profile != null && profile.getFullName() != null ? profile.getFullName() : "Người dùng BodyPilot").append("\n");

        if (metric != null) {
            sb.append("Cân nặng: ").append(metric.getWeight()).append(" kg, ");
            sb.append("Chiều cao: ").append(metric.getHeightCm()).append(" cm, ");
            sb.append("BMI: ").append(metric.getBmi() != null ? String.format("%.1f", metric.getBmi()) : "Chưa rõ").append(", ");
            sb.append("Target Calo hàng ngày: ").append(metric.getTargetCalories() != null ? metric.getTargetCalories().intValue() : 2000).append(" kcal\n");
        }

        if (goal != null) {
            sb.append("Mục tiêu hiện tại: ").append(goal.getType()).append(" (Cân nặng mục tiêu: ").append(goal.getTargetWeight() != null ? goal.getTargetWeight() + "kg" : "Duy trì").append(")\n");
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

    private String buildSystemInstruction(String userContext) {
        return "Bạn là \"BodyPilot AI Coach\" - Trợ lý y tế, dinh dưỡng và huấn luyện viên cá nhân thông minh của ứng dụng BodyPilot.\n\n" +
                "[THÔNG TIN THỂ TRẠNG NGƯỜI DÙNG HẠN ĐỊNH]:\n" + userContext + "\n" +
                "[PHẠM VI HỖ TRỢ CHI CHO PHÉP]:\n" +
                "1. Tư vấn thực đơn, calo, dinh dưỡng, vóc dáng và phân bổ Macro (Protein, Fat, Carbs).\n" +
                "2. Hướng dẫn kỹ thuật bài tập, lịch tập thể hình, cardio, giảm mỡ, tăng cơ.\n" +
                "3. Tư vấn an toàn chấn thương thể thao & dị ứng thực phẩm.\n" +
                "4. Giải đáp thắc mắc sử dụng ứng dụng BodyPilot.\n\n" +
                "[QUY TẮC QUAN TRỌNG BẮT BUỘC (GUARDRAILS)]:\n" +
                "1. Bạn CHỈ trả lời các câu hỏi NẰM TRONG phạm vi Dinh dưỡng, Tập luyện & BodyPilot.\n" +
                "2. Nếu người dùng hỏi chủ đề ngoài lề (như viết code, lập trình, giải toán, phim ảnh, chính trị, thời tiết...), bạn PHẢI TỪ CHỐI LỊCH SỰ theo đúng mẫu:\n" +
                "   \"Xin lỗi bạn, tôi là trợ lý AI chuyên biệt về Dinh Dưỡng & Tập Luyện của BodyPilot. Tôi không thể hỗ trợ các thắc mắc ngoài lĩnh vực sức khỏe và thể thao. Bạn có cần tôi hỗ trợ gì về thực đơn hay bài tập hôm nay không?\"\n" +
                "3. Trả lời thân thiện, xưng hô \"tôi\" và \"bạn\", ngắn gọn, dễ hiểu và cô đọng (dưới 150 từ), phù hợp đọc trên điện thoại di động.";
    }

    private String buildPromptWithHistory(List<ChatMessageDTO> history, String userQuery) {
        StringBuilder sb = new StringBuilder();

        // Include last 6 messages max
        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 6);
            sb.append("[LỊCH SỬ HỘI THOẠI GẦN ĐÂY]:\n");
            for (int i = start; i < history.size(); i++) {
                ChatMessageDTO msg = history.get(i);
                sb.append(msg.getRole().equalsIgnoreCase("user") ? "Người dùng: " : "AI Coach: ")
                        .append(msg.getContent())
                        .append("\n");
            }
            sb.append("\n");
        }

        sb.append("[CÂU HỎI MỚI CỦA NGƯỜI DÙNG]:\n").append(userQuery);
        return sb.toString();
    }
}
