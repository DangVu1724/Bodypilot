package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.dto.nutrition.MealSlotDTO;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.model.enums.DislikedFoodGroup;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Slf4j
public class DietSuggestionHelper {

    private final FoodRepository foodRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public List<FoodCandidate> getBalancedFoodCandidates(UUID userId, String goalType) {
        log.info("[Candidates Log] Starting getBalancedFoodCandidates...");
        log.info("[Candidates Log] Retrieving allergies from repository...");
        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        log.info("[Candidates Log] Retrieving diets from repository...");
        List<UserDietPreference> diets = dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
        log.info("[Candidates Log] Retrieving food preferences from repository...");
        List<UserFoodPreference> dislikedFoods = foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);

        log.info("[Candidates Log] Filtering foods...");
        List<Food> filteredFoods = getFilteredFoods(allergies, diets, dislikedFoods);
        log.info("[Candidates Log] Filtered foods size: {}", filteredFoods.size());

        log.info("[Candidates Log] Selecting balanced foods (limit 300)...");
        List<Food> limitedFoods = selectBalancedFoods(filteredFoods, 300, goalType, diets);
        log.info("[Candidates Log] Selected balanced foods size: {}", limitedFoods.size());

        log.info("[Candidates Log] Mapping to FoodCandidate list...");
        return limitedFoods.stream()
                .map(f -> new FoodCandidate(
                        f.getId(),
                        f.getName(),
                        f.getCaloriesPer100g().doubleValue(),
                        f.getProteinPer100g().doubleValue(),
                        f.getFatPer100g().doubleValue(),
                        f.getCarbsPer100g().doubleValue(),
                        f.getCategory() != null && f.getCategory().getCode() != null ? f.getCategory().getCode().toUpperCase() : "OTHERS"
                ))
                .collect(Collectors.toList());
    }

    public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                              List<UserAllergy> allergies, List<UserDietPreference> diets, 
                              List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate, Integer days) {
        return buildPrompt(profile, goal, metric, allergies, diets, dislikes, candidates, startDate, days, null);
    }

    public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                              List<UserAllergy> allergies, List<UserDietPreference> diets, 
                              List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate, Integer days, String userFeedback) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo thực đơn ăn uống trong ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(" dựa trên thông tin người dùng và danh sách thực phẩm được cung cấp bên dưới.\n\n");

        if (profile != null) {
            sb.append("- Giới tính: ").append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật").append("\n");
            sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật").append("\n");
            sb.append("- Chiều cao: ").append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm" : "Chưa cập nhật").append("\n");
            sb.append("- Cân nặng hiện tại: ").append(profile.getWeight() != null ? profile.getWeight() + " kg" : "Chưa cập nhật").append("\n");
            sb.append("- Mức độ hoạt động: ").append(profile.getActivityLevel() != null ? translateActivityLevel(profile.getActivityLevel()) : "Chưa cập nhật").append("\n");
            sb.append("- Ngân sách ăn uống: ").append(profile.getFoodBudget() != null ? translateBudget(profile.getFoodBudget().name()) : "Chưa cập nhật").append("\n");
        }

        if (goal != null) {
            sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
            sb.append("- Cân nặng mục tiêu: ").append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg" : "Chưa cập nhật").append("\n");
        }

        if (metric != null && metric.getTargetCalories() != null) {
            sb.append("- Lượng calo tiêu thụ mục tiêu mỗi ngày: ").append(metric.getTargetCalories().intValue()).append(" kcal (LƯU Ý: Vui lòng thiết kế thực đơn 3 bữa sao cho tổng calo hàng ngày xấp xỉ đạt mục tiêu này, sai số trong khoảng +/- 10%)\n");
        }

        if (!allergies.isEmpty()) {
            String allergyNames = allergies.stream()
                    .map(a -> a.getAllergyMaster().getName())
                    .collect(Collectors.joining(", "));
            sb.append("- Dị ứng thực phẩm (BẮT BUỘC TRÁNH): ").append(allergyNames).append("\n");
        }

        if (!diets.isEmpty()) {
            String dietNames = diets.stream()
                    .map(d -> d.getDietTag().getName())
                    .collect(Collectors.joining(", "));
            sb.append("- Chế độ ăn ưu tiên: ").append(dietNames).append("\n");
        }

        if (!dislikes.isEmpty()) {
            String dislikeNames = dislikes.stream()
                    .map(d -> translateDislikeGroup(d.getDislikedFoodGroup().name()))
                    .collect(Collectors.joining(", "));
            sb.append("- Nhóm thực phẩm không thích: ").append(dislikeNames).append("\n");
        }

        if (userFeedback != null && !userFeedback.trim().isEmpty()) {
            sb.append("\n- YÊU CẦU ĐẶC BIỆT / PHẢN HỒI ĐIỀU CHỈNH TỪ NGƯỜI DÙNG: ").append(userFeedback.trim()).append("\n");
            sb.append("(HÃY ĐẶC BIỆT LƯU Ý VÀ ĐIỀU CHỈNH THỰC ĐƠN ĐÁP ỨNG CHÍNH XÁC YÊU CẦU NÀY CỦA NGƯỜI DÙNG)\n");
        }

        sb.append("\nDANH SÁCH THỰC PHẨM ĐƯỢC PHÉP SỬ DỤNG (PHÂN LOẠI THEO NGUYÊN BẢN DANH MỤC CỦA ỨNG DỤNG - TỐI ĐA 30 MÓN MỖI DANH MỤC):\n");
        Map<String, List<FoodCandidate>> groupedByCat = new LinkedHashMap<>();
        for (FoodCandidate c : candidates) {
            String catCode = (c.getCategoryCode() != null && !c.getCategoryCode().trim().isEmpty()) ? c.getCategoryCode().toUpperCase() : "OTHERS";
            groupedByCat.computeIfAbsent(catCode, k -> new ArrayList<>()).add(c);
        }

        for (Map.Entry<String, List<FoodCandidate>> entry : groupedByCat.entrySet()) {
            try {
                sb.append("\n📌 Danh mục [").append(entry.getKey()).append("] (").append(entry.getValue().size()).append(" món):\n")
                  .append(objectMapper.writeValueAsString(entry.getValue())).append("\n");
            } catch (Exception ignored) {}
        }

        String goalCode = goal != null && goal.getType() != null ? goal.getType().toUpperCase() : "";

        sb.append("\nQUY TẮC CỐT LÕI VĂN HÓA ẨM THỰC VIỆT NAM VÀ DINH DƯỠNG (BẮT BUỘC TUÂN THỦ NGHIÊM NGẶT):\n");
        sb.append("1. RÀNG BUỘC SỐ BỮA: Mỗi ngày BẮT BUỘC CHỈ TẠO ĐÚNG 3 BỮA CHÍNH: BREAKFAST (Bữa sáng), LUNCH (Bữa trưa), DINNER (Bữa tối). TUYỆT ĐỐI KHÔNG TẠO THÊM BẤT KỲ MEAL SLOT NÀO KHÁC.\n");
        sb.append("2. CẤU TRÚC BỮA SÁNG (BREAKFAST) - BẮT BUỘC FROM 2 ĐẾN 3 MÓN PHỐI HỢP PHÙ HỢP VÀ CHUẨN THỰC TẾ:\n");
        sb.append("   - Bữa sáng BẮT BUỘC gồm từ 2 đến 3 món ăn được phối hợp tự nhiên, đa dạng và thực tế (như các combo điểm tâm chuẩn):\n");
        sb.append("     + COMBO MÓN NƯỚC: 1 Món nước (`NOODLE_SOUP` như Phở, Bún bò, Cháo...) + 1 Đồ uống (`BEVERAGE`/`DAIRY` như Sữa tươi, Sữa chua, Cà phê) HOẶC 1 phần Trái cây.\n");
        sb.append("     + COMBO BÁNH MÌ & SANDWICH: Bánh mì nguyên cám / Bánh mì cám yến mạch / Sandwich / French Toast (`GRAIN`/`DRY_DISH`) + 1 Món đạm nhẹ (Trứng gà ốp la/luộc, Ức gà) + 1 Đồ uống/Sinh tố (Sinh tố bơ, Sữa tươi, Cà phê) HOẶC 1 quả Trái cây (Chuối, Táo).\n");
        sb.append("     + COMBO MÓN KHÔ TRUYỀN THỐNG: Xôi, Nui xào, Bánh cuốn (`DRY_DISH`) + 1 Đồ uống (Sữa, Nước ép) HOẶC 1 Trái cây.\n");
        sb.append("     + COMBO YẾN MẠCH & SỮA CHUA: Yến mạch / Sữa chua Hy Lạp + Hạt / Trái cây + Trứng luộc / Sữa.\n");
        sb.append("   - TUYỆT ĐỐI CẤM ĐƯA CÁC MÓN MẶN ĂN CƠM TRƯA/TỐI VÀO BỮA SÁNG: Cấm đưa các món mặn mâm cơm như Đậu phụ chiên, Rau củ xào, Thịt kho, Cá nướng, Thịt xào... vào Bữa sáng!\n");
        sb.append("3. CẤU TRÚC BỮA TỐI (DINNER):\n");
        sb.append("   - BẮT BUỘC trong danh sách `items` của Bữa tối phải chứa 1 món CƠM ĐÃ NẤU (Cơm trắng hoặc Cơm gạo lứt) làm tinh bột chính, ăn kèm 1 món mặn quen thuộc và rau củ/canh.\n");
        sb.append("4. CẤU TRÚC MÂM CƠM VÀ PHÂN BỔ MÓN ĂN HỢP LÝ (VĂN HÓA VIỆT NAM):\n");
        sb.append("   - Bữa trưa và Bữa tối phải được phối hợp chuẩn mâm cơm Việt Nam: 1 Tinh bột chính (Cơm/Gạo lứt) + 1 Món mặn giàu đạm chính (như Thịt kho, Ức gà áp chảo, Cá kho/sốt cà, Thịt bò xào, Trứng rán...) + 1 Món Rau/Canh (Rau muống luộc, Canh cải, Canh bí, Salad).\n");
        sb.append("   - TUYỆT ĐỐI KHÔNG xếp 2 món mặn nướng / khó tiêu trong cùng 1 bữa (Ví dụ: KHÔNG ĐƯỢC kết hợp Cá nướng + Dê nướng trong cùng 1 bữa trưa).\n");
        sb.append("   - Ưu tiên chọn các món ăn dân dã, quen thuộc với người Việt. Tránh kết hợp các món xa lạ hoặc kỳ lạ.\n");
        sb.append("5. QUY TẮC TRÁI CÂY TRÁNG MIỆNG (FRUITS):\n");
        sb.append("   - BẮT BUỘC NGÀY NÀO CŨNG PHẢI CÓ TRÁI CÂY (thuộc danh mục `FRUIT` như Táo, Chuối, Cam, Dưa hấu, Kiwi, Dâu tây, Thanh long, Lựu, Dứa...).\n");
        sb.append("   - Mỗi ngày có thể có từ 1 đến 2 bữa chứa trái cây (ví dụ: Bữa sáng & Bữa trưa, hoặc Bữa trưa & Bữa tối).\n");
        sb.append("   - NẾU MỘT NGÀY CÓ 2 BỮA CÓ TRÁI CÂY: Hai loại trái cây ở 2 bữa đó BẮT BUỘC PHẢI KHÁC NHAU (Ví dụ: Bữa trưa ăn Táo thì Bữa tối ăn Dưa hấu hoặc Chuối; TUYỆT ĐỐI KHÔNG chọn cùng 1 loại trái cây cho 2 bữa trong cùng một ngày).\n");
        sb.append("   - Trong mỗi bữa ăn, CHỈ ĐƯỢC chọn tối đa 1 phần / 1 loại trái cây duy nhất làm món tráng miệng hoặc ăn kèm.\n");

        if (goalCode.contains("LOSE") || goalCode.contains("CUTTING")) {
            sb.append("6. QUY TẮC PHỐI BỮA CHO GIẢM CÂN / SIẾT CƠ / ĂN KIÊNG (LOSE / CUTTING):\n");
            sb.append("   - BỮA SÁNG (BREAKFAST): Linh hoạt chọn các combo ăn kiêng thanh đạm, ít calo nhưng đủ đạm: Trứng luộc / Trứng ốp la không dầu + Bánh mì cám yến mạch / Bánh mì nguyên cám / Yến mạch + Sữa không đường / Cà phê đen / Trái cây ít đường (Táo, Dâu). Tránh Phở bún nhiều mỡ hay xôi chiên.\n");
            sb.append("   - BỮA TRƯA & TỐI (LUNCH & DINNER): Ưu tiên đạm nạc (Ức gà / Bò nạc / Cá / Đậu phụ) + Cơm gạo lứt + Nhiều rau xanh/Canh. Bữa tối lượng cơm giảm 50% so với bữa trưa.\n");
        } else if (goalCode.contains("GAIN_0") || goalCode.contains("GAIN_1") || goalCode.contains("BULKING")) {
            sb.append("6. QUY TẮC PHỐI BỮA CHO TĂNG CÂN / TĂNG CƠ (BULKING / GAIN):\n");
            sb.append("   - BỮA SÁNG (BREAKFAST): Linh hoạt chọn các combo giàu năng lượng & đạm cao: Phở / Bún bò / Hủ tiếu + Trứng luộc / Sữa tươi; HOẶC Sandwich / Bánh mì + Trứng gà + Sinh tố bơ / Sinh tố Protein / Chuối.\n");
            sb.append("   - BỮA TRƯA & TỐI (LUNCH & DINNER): Đạm dồi dào (Gà, Bò, Cá, Heo nạc) + Cơm đầy đủ + Món xào / Canh / Trái cây bổ sung năng lượng.\n");
        } else if (goalCode.contains("MUSCLE")) {
            sb.append("6. QUY TẮC PHỐI BỮA CHO TĂNG CƠ GIẢM MỠ (MUSCLE RECOMPOSITION):\n");
            sb.append("   - BỮA SÁNG (BREAKFAST): Đạm cao & Carb sạch: Trứng luộc / Lòng trắng trứng / Ức gà + Bánh mì cám yến mạch / Yến mạch + Sinh tố đạm / Sữa chua Hy Lạp + Táo / Chuối.\n");
            sb.append("   - BỮA TRƯA & TỐI (LUNCH & DINNER): Đạm nạc dồi dào + Cơm gạo lứt vừa đủ + Nhiều rau xanh.\n");
        } else if (goalCode.contains("HEALTHY") || goalCode.contains("EAT_CLEAN")) {
            sb.append("6. QUY TẮC PHỐI BỮA CHO ĂN CLEAN / SỨC KHỎE (HEALTHY LIFESTYLE):\n");
            sb.append("   - BỮA SÁNG (BREAKFAST): Yến mạch nguyên cám / Bánh mì cám yến mạch + Trứng luộc / Sữa chua Hy Lạp + Trái cây tươi (Táo, Kiwi, Cam) & Sữa hạt.\n");
            sb.append("   - BỮA TRƯA & TỐI (LUNCH & DINNER): Thực phẩm nguyên bản (hấp, nướng, luộc) + Cơm gạo lứt + Rau củ tươi đa dạng.\n");
        } else {
            sb.append("6. QUY TẮC PHỐI BỮA KHI DUY TRÌ CÂN NẶNG (MAINTAIN):\n");
            sb.append("   - BỮA SÁNG (BREAKFAST): Linh hoạt lựa chọn combo phù hợp (Phở / Bún / Bánh mì cám / Sandwich / Yến mạch + Trứng / Sữa tươi / Sinh tố / Trái cây).\n");
            sb.append("   - BỮA TRƯA & TỐI (LUNCH & DINNER): Cân bằng đạm, tinh bột cơm và rau củ.\n");
        }

        sb.append("7. ĐA DẠNG MÓN ĂN: Tuyệt đối không lặp lại cùng một món quá 2 lần trong tuần. Hãy xoay vòng đa dạng giữa các ngày.\n");

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        sb.append("Bạn PHẢI trả về một JSON array duy nhất đại diện cho thực đơn gợi ý của ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
        sb.append("RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN thực phẩm từ danh sách Candidates ở trên. Bắt buộc phải khớp đúng UUID của thực phẩm đó trong trường `foodId`.\n");
        sb.append("Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
        sb.append("[\n");
        sb.append("  {\n");
        sb.append("    \"date\": \"YYYY-MM-DD\",\n");
        sb.append("    \"note\": \"Ghi chú tổng quan dinh dưỡng hoặc lời khuyên cho ngày này\",\n");
        sb.append("    \"isAiGenerated\": true,\n");
        sb.append("    \"mealSlots\": [\n");
        sb.append("      {\n");
        sb.append("        \"mealType\": \"BREAKFAST\", // BẮT BUỘC CHỈ CÓ 3 BỮA: BREAKFAST, LUNCH, DINNER\n");
        sb.append("        \"customName\": \"Bữa sáng\",\n");
        sb.append("        \"orderIndex\": 0,\n");
        sb.append("        \"items\": [\n");
        sb.append("          {\n");
        sb.append("            \"foodId\": \"UUID của thực phẩm được chọn\", // Phải khớp chính xác với trường id trong danh sách Candidates\n");
        sb.append("            \"foodName\": \"Tên thực phẩm được chọn\", // Phải khớp chính xác với trường name trong Candidates\n");
        sb.append("            \"servingQuantity\": 150.0 // Khẩu phần ăn tính bằng gram (ví dụ: 100.0, 150.0, 200.0)\n");
        sb.append("          }\n");
        sb.append("        ]\n");
        sb.append("      },\n");
        sb.append("      {\n");
        sb.append("        \"mealType\": \"LUNCH\",\n");
        sb.append("        \"customName\": \"Bữa trưa\",\n");
        sb.append("        \"orderIndex\": 1,\n");
        sb.append("        \"items\": [ ... ]\n");
        sb.append("      },\n");
        sb.append("      {\n");
        sb.append("        \"mealType\": \"DINNER\",\n");
        sb.append("        \"customName\": \"Bữa tối\",\n");
        sb.append("        \"orderIndex\": 2,\n");
        sb.append("        \"items\": [ ... ]\n");
        sb.append("      }\n");
        sb.append("    ]\n");
        sb.append("  }\n");
        sb.append("]\n");

        return sb.toString();
    }

    public String processAndLinkFoods(String rawJson) {
        return processAndLinkFoods(rawJson, null);
    }

    public String processAndLinkFoods(String rawJson, BigDecimal targetCalories) {
        try {
            if (rawJson == null || rawJson.trim().isEmpty()) {
                return "[]";
            }
            // Sanitize markdown fences from Gemini AI response if present
            String cleanedJson = rawJson.trim();
            if (cleanedJson.startsWith("```json")) {
                cleanedJson = cleanedJson.substring(7);
            } else if (cleanedJson.startsWith("```")) {
                cleanedJson = cleanedJson.substring(3);
            }
            if (cleanedJson.endsWith("```")) {
                cleanedJson = cleanedJson.substring(0, cleanedJson.length() - 3);
            }
            cleanedJson = cleanedJson.trim();

            JsonNode root = objectMapper.readTree(cleanedJson);
            if (!root.isArray()) {
                if (root.isObject()) {
                    if (root.has("days") && root.get("days").isArray()) {
                        root = root.get("days");
                    } else if (root.has("suggestions") && root.get("suggestions").isArray()) {
                        root = root.get("suggestions");
                    } else if (root.has("data") && root.get("data").isArray()) {
                        root = root.get("data");
                    } else if (root.has("result") && root.get("result").isArray()) {
                        root = root.get("result");
                    } else {
                        return rawJson;
                    }
                } else {
                    return rawJson;
                }
            }

            List<Food> allFoods = getAllFoodsCached();
            Map<UUID, Food> foodMap = allFoods.stream()
                    .collect(Collectors.toMap(
                            Food::getId,
                            f -> f,
                            (f1, f2) -> f1
                    ));
            Map<String, Food> nameMap = allFoods.stream()
                    .collect(Collectors.toMap(
                            f -> f.getName().toLowerCase().trim(),
                            f -> f,
                            (f1, f2) -> f1
                    ));

            List<DailyEatingDTO> list = new ArrayList<>();
            for (JsonNode dayNode : root) {
                LocalDate date = LocalDate.parse(dayNode.path("date").asText());
                String note = dayNode.path("note").asText();
                boolean isAiGenerated = dayNode.path("isAiGenerated").asBoolean(true);

                List<MealSlotDTO> mealSlots = new ArrayList<>();
                JsonNode slotsNode = dayNode.path("mealSlots");
                if (slotsNode.isArray()) {
                    for (JsonNode slotNode : slotsNode) {
                        String mealTypeStr = slotNode.path("mealType").asText("BREAKFAST");
                        MealType mealType = MealType.valueOf(mealTypeStr);
                        String customName = slotNode.path("customName").asText("");
                        Integer orderIndex = slotNode.path("orderIndex").asInt(0);

                        List<MealItemDTO> items = new ArrayList<>();
                        JsonNode itemsNode = slotNode.path("items");
                        if (itemsNode.isArray()) {
                            int itemOrder = 0;
                            for (JsonNode itemNode : itemsNode) {
                                String foodIdStr = itemNode.path("foodId").asText("").trim();
                                String foodNameStr = itemNode.path("foodName").asText("").trim();
                                BigDecimal servingQuantity = new BigDecimal(itemNode.path("servingQuantity").asText("100"));
                                
                                Food food = null;
                                if (!foodIdStr.isEmpty()) {
                                    try {
                                        UUID foodId = UUID.fromString(foodIdStr);
                                        food = foodMap.get(foodId);
                                    } catch (Exception ignored) {}
                                }
                                if (food == null && !foodNameStr.isEmpty()) {
                                    food = nameMap.get(foodNameStr.toLowerCase());
                                }
                                if (food == null && !foodNameStr.isEmpty()) {
                                    String key = foodNameStr.toLowerCase();
                                    food = allFoods.stream()
                                            .filter(f -> f.getName().toLowerCase().contains(key) || key.contains(f.getName().toLowerCase()))
                                            .findFirst()
                                            .orElse(null);
                                }

                                if (food != null) {
                                    BigDecimal factor = servingQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                                    BigDecimal calories = food.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                    BigDecimal protein = food.getProteinPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                    BigDecimal fat = food.getFatPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                    BigDecimal carbs = food.getCarbsPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                    BigDecimal fiber = food.getFiberPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP);
                                    
                                    String unit = "g";

                                    items.add(MealItemDTO.builder()
                                            .foodId(food.getId())
                                            .servingQuantity(servingQuantity)
                                            .orderIndex(itemNode.has("orderIndex") ? itemNode.path("orderIndex").asInt() : itemOrder++)
                                            .foodName(food.getName())
                                            .calories(calories)
                                            .protein(protein)
                                            .fat(fat)
                                            .carbs(carbs)
                                            .fiber(fiber)
                                            .servingUnit(unit)
                                            .imageUrl(food.getImageUrl())
                                            .isCustom(false)
                                            .isEaten(false)
                                            .build());
                                } else {
                                    log.warn("Suggested food ID [{}] / Name [{}] not found in database candidates.", foodIdStr, foodNameStr);
                                }
                            }
                        }

                        mealSlots.add(MealSlotDTO.builder()
                                .mealType(mealType)
                                .customName(customName)
                                .orderIndex(orderIndex)
                                .isEaten(false)
                                .items(items)
                                .build());
                    }
                }

                BigDecimal totalCal = mealSlots.stream()
                        .flatMap(slot -> slot.getItems().stream())
                        .map(item -> item.getCalories() != null ? item.getCalories() : BigDecimal.ZERO)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);

                // Exact Macro Scaler logic: scale servingQuantity to closely match targetCalories if provided
                if (targetCalories != null && targetCalories.compareTo(BigDecimal.ZERO) > 0 && totalCal.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal scaleFactor = targetCalories.divide(totalCal, 4, RoundingMode.HALF_UP);
                    // Restrict scale factor between 0.5 and 2.0 to avoid extreme distortion
                    if (scaleFactor.compareTo(new BigDecimal("0.5")) < 0) {
                        scaleFactor = new BigDecimal("0.5");
                    } else if (scaleFactor.compareTo(new BigDecimal("2.0")) > 0) {
                        scaleFactor = new BigDecimal("2.0");
                    }

                    for (MealSlotDTO slot : mealSlots) {
                        for (MealItemDTO item : slot.getItems()) {
                            if (item.getFoodId() != null && foodMap.containsKey(item.getFoodId())) {
                                Food food = foodMap.get(item.getFoodId());
                                BigDecimal scaledQuantity = item.getServingQuantity().multiply(scaleFactor).setScale(1, RoundingMode.HALF_UP);
                                // Bound quantity between 30g and 500g
                                if (scaledQuantity.compareTo(new BigDecimal("30.0")) < 0) {
                                    scaledQuantity = new BigDecimal("30.0");
                                } else if (scaledQuantity.compareTo(new BigDecimal("500.0")) > 0) {
                                    scaledQuantity = new BigDecimal("500.0");
                                }

                                BigDecimal factor = scaledQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
                                item.setServingQuantity(scaledQuantity);
                                item.setCalories(food.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                item.setProtein(food.getProteinPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                item.setFat(food.getFatPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                item.setCarbs(food.getCarbsPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                                item.setFiber(food.getFiberPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
                            }
                        }
                    }

                    // Recalculate total calories after scaling
                    totalCal = mealSlots.stream()
                            .flatMap(slot -> slot.getItems().stream())
                            .map(item -> item.getCalories() != null ? item.getCalories() : BigDecimal.ZERO)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                }

                list.add(DailyEatingDTO.builder()
                        .date(date)
                        .note(note)
                        .isAiGenerated(isAiGenerated)
                        .totalCaloriesPlanned(totalCal)
                        .totalCaloriesEaten(BigDecimal.ZERO)
                        .mealSlots(mealSlots)
                        .build());
            }

            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            log.error("Error post-processing AI meal suggestion JSON: ", e);
            return rawJson;
        }
    }

    public String getFallbackJson(LocalDate startDate, String message, Integer days) {
        try {
            List<DailyEatingDTO> fallbackList = new ArrayList<>();
            for (int i = 0; i < days; i++) {
                LocalDate date = startDate.plusDays(i);
                fallbackList.add(DailyEatingDTO.builder()
                        .date(date)
                        .note(message)
                        .isAiGenerated(true)
                        .mealSlots(new ArrayList<>())
                        .build());
            }
            return objectMapper.writeValueAsString(fallbackList);
        } catch (Exception e) {
            return "[]";
        }
    }

    private List<Food> cachedFoods = null;
    private long lastCacheTime = 0;
    private static final long CACHE_TTL_MS = 15 * 60 * 1000; // 15 phút

    private List<Food> getAllFoodsCached() {
        long now = System.currentTimeMillis();
        if (cachedFoods == null || (now - lastCacheTime) > CACHE_TTL_MS) {
            synchronized (this) {
                if (cachedFoods == null || (now - lastCacheTime) > CACHE_TTL_MS) {
                    log.info("[FilteredFoods Log] Querying all foods from foodRepository (Cache Miss/Expired)...");
                    long start = System.currentTimeMillis();
                    cachedFoods = foodRepository.findAllWithRelations();
                    lastCacheTime = System.currentTimeMillis();
                    log.info("[FilteredFoods Log] Loaded {} foods from database in {} ms.", cachedFoods.size(), (lastCacheTime - start));
                }
            }
        } else {
            log.info("[FilteredFoods Log] Reusing {} cached foods from memory.", cachedFoods.size());
        }
        return new ArrayList<>(cachedFoods);
    }

    private List<Food> getFilteredFoods(List<UserAllergy> allergies, List<UserDietPreference> diets, List<UserFoodPreference> dislikes) {
        List<Food> foods = getAllFoodsCached();
        log.info("[FilteredFoods Log] Total foods to filter: {}", foods.size());
        
        if (allergies != null && !allergies.isEmpty()) {
            log.info("[FilteredFoods Log] Filtering allergies (count: {})...", allergies.size());
            for (UserAllergy allergy : allergies) {
                if (allergy.getAllergyMaster() == null) continue;
                String allergyName = allergy.getAllergyMaster().getName().toLowerCase().trim();
                String allergyCode = allergy.getAllergyMaster().getCode() != null ? allergy.getAllergyMaster().getCode().toLowerCase().trim() : "";
                
                foods = foods.stream()
                    .filter(f -> {
                        if (f.getCategory() != null) {
                            String catName = f.getCategory().getName().toLowerCase();
                            String catCode = f.getCategory().getCode() != null ? f.getCategory().getCode().toLowerCase() : "";
                            if (catName.contains(allergyName) || catCode.contains(allergyCode) || allergyName.contains(catName) || allergyCode.contains(catCode)) {
                                return false;
                            }
                        }
                        String name = f.getName().toLowerCase();
                        String desc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
                        return !name.contains(allergyName) && !desc.contains(allergyName);
                    })
                    .collect(Collectors.toList());
            }
            log.info("[FilteredFoods Log] Foods after allergies filtering: {}", foods.size());
        }
        
        if (diets != null && !diets.isEmpty()) {
            log.info("[FilteredFoods Log] Soft-evaluating diets for vegetarian/vegan exclusions if applicable...");
            for (UserDietPreference preference : diets) {
                if (preference.getDietTag() == null || preference.getDietTag().getName() == null) continue;
                String tagName = preference.getDietTag().getName().toLowerCase();
                if (tagName.contains("chay") || tagName.contains("vegan") || tagName.contains("vegetarian")) {
                    foods = foods.stream().filter(f -> {
                        String catName = f.getCategory() != null ? f.getCategory().getName().toLowerCase() : "";
                        String catCode = f.getCategory() != null && f.getCategory().getCode() != null ? f.getCategory().getCode().toLowerCase() : "";
                        return !catName.contains("thịt") && !catCode.contains("meat") 
                            && !catName.contains("hải sản") && !catCode.contains("seafood");
                    }).collect(Collectors.toList());
                }
            }
            log.info("[FilteredFoods Log] Foods after diets evaluation: {}", foods.size());
        }
        
        if (dislikes != null && !dislikes.isEmpty()) {
            log.info("[FilteredFoods Log] Filtering dislikes (count: {})...", dislikes.size());
            for (UserFoodPreference preference : dislikes) {
                DislikedFoodGroup group = preference.getDislikedFoodGroup();
                if (group == null) continue;
                
                foods = foods.stream()
                    .filter(f -> !isDislikedFood(f, group))
                    .collect(Collectors.toList());
            }
            log.info("[FilteredFoods Log] Foods after dislikes filtering: {}", foods.size());
        }
        
        // Exclude OTHERS/OTHER category foods from AI candidates
        foods = foods.stream()
                .filter(f -> f.getCategory() != null && f.getCategory().getCode() != null
                        && !"OTHERS".equalsIgnoreCase(f.getCategory().getCode())
                        && !"OTHER".equalsIgnoreCase(f.getCategory().getCode()))
                .collect(Collectors.toList());
        log.info("[FilteredFoods Log] Foods after excluding OTHERS category: {}", foods.size());

        // Filter foods with is_recommended = true
        List<Food> recommendedFoods = foods.stream()
                .filter(f -> Boolean.TRUE.equals(f.getIsRecommended()))
                .collect(Collectors.toList());
        if (!recommendedFoods.isEmpty()) {
            foods = recommendedFoods;
            log.info("[FilteredFoods Log] Foods after is_recommended=true filter: {}", foods.size());
        }

        return foods;
    }
    
    private boolean isDislikedFood(Food f, DislikedFoodGroup group) {
        String name = f.getName().toLowerCase();
        String desc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
        String catName = f.getCategory() != null ? f.getCategory().getName().toLowerCase() : "";
        String catCode = f.getCategory() != null && f.getCategory().getCode() != null ? f.getCategory().getCode().toLowerCase() : "";
        
        return switch (group) {
            case SEAFOOD -> {
                if (catName.contains("hải sản") || catCode.contains("seafood")) yield true;
                List<String> sfKeywords = Arrays.asList("tôm", "cua", "cá", "mực", "nghêu", "sò", "ốc", "hến", "bạch tuộc", "sứa", "hàu", "tôm hùm", "seafood", "fish", "shrimp", "squid", "crab", "octopus");
                yield sfKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case ORGAN_MEAT -> {
                List<String> organKeywords = Arrays.asList("lòng", "tim", "gan", "cật", "phèo", "mề", "sách", "dồi", "nội tạng", "dạ dày heo", "organ", "liver", "kidney", "gizzard");
                yield organKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case DAIRY_PRODUCTS -> {
                if (catName.contains("sữa") || catCode.contains("dairy") || catCode.contains("milk")) yield true;
                List<String> dairyKeywords = Arrays.asList("sữa", "phô mai", "bơ", "milk", "cheese", "butter", "dairy", "yogurt", "sữa chua", "váng sữa");
                yield dairyKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case FRIED_FOOD, FAST_FOOD -> {
                List<String> fastKeywords = Arrays.asList("chiên", "rán", "quay", "nướng dầu", "fastfood", "hamburger", "pizza", "fried", "kfc", "jollibee", "mcdonald");
                yield fastKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case SPICY_FOOD -> {
                List<String> spicyKeywords = Arrays.asList("cay", "ớt", "chilli", "spicy");
                yield spicyKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case SUGARY_FOOD -> {
                List<String> sugarKeywords = Arrays.asList("kẹo", "bánh ngọt", "sô cô la", "chocolate", "candy", "sweet", "đường cát", "nước ngọt", "soda");
                yield sugarKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            case PROCESSED_FOOD -> {
                List<String> processedKeywords = Arrays.asList("xúc xích", "lạp xưởng", "thịt nguội", "lạp sườn", "giăm bông", "ham", "sausage", "đồ hộp", "cá hộp", "thịt hộp");
                yield processedKeywords.stream().anyMatch(k -> name.contains(k) || desc.contains(k));
            }
            default -> false;
        };
    }

    private List<Food> selectBalancedFoods(List<Food> foods, int limit, String goalType, List<UserDietPreference> diets) {
        if (foods.size() <= limit) {
            return foods;
        }

        Map<UUID, List<Food>> categoryGroups = new HashMap<>();
        UUID nullCategoryUuid = UUID.randomUUID();
        Random random = new Random();
        
        Map<Food, Double> foodScores = new HashMap<>();
        for (Food food : foods) {
            UUID catId = (food.getCategory() != null) ? food.getCategory().getId() : nullCategoryUuid;
            categoryGroups.computeIfAbsent(catId, k -> new ArrayList<>()).add(food);
            double score = calculateFoodScore(food, goalType, diets) + (random.nextDouble() * 30.0);
            foodScores.put(food, score);
        }

        for (List<Food> groupFoods : categoryGroups.values()) {
            groupFoods.sort((f1, f2) -> Double.compare(foodScores.get(f2), foodScores.get(f1)));
        }

        List<Food> selectedFoods = new ArrayList<>();
        List<UUID> catIds = new ArrayList<>(categoryGroups.keySet());

        Map<UUID, Integer> categoryCounts = new HashMap<>();
        for (UUID catId : catIds) {
            categoryCounts.put(catId, 0);
        }

        int index = 0;
        boolean addedAny;
        do {
            addedAny = false;
            for (UUID catId : catIds) {
                List<Food> groupFoods = categoryGroups.get(catId);
                int count = categoryCounts.get(catId);

                String catCode = null;
                if (!groupFoods.isEmpty() && groupFoods.get(0).getCategory() != null) {
                    catCode = groupFoods.get(0).getCategory().getCode();
                }

                int maxPerCategoryLimit = getMaxCategoryLimit(catCode, goalType);

                if (count < maxPerCategoryLimit && index < groupFoods.size()) {
                    selectedFoods.add(groupFoods.get(index));
                    categoryCounts.put(catId, count + 1);
                    addedAny = true;
                    if (selectedFoods.size() >= limit) {
                        break;
                    }
                }
            }
            index++;
        } while (addedAny && selectedFoods.size() < limit);

        return selectedFoods;
    }

    private double calculateFoodScore(Food food, String goalType, List<UserDietPreference> diets) {
        double protein = food.getProteinPer100g() != null ? food.getProteinPer100g().doubleValue() : 0.0;
        double fat = food.getFatPer100g() != null ? food.getFatPer100g().doubleValue() : 0.0;
        double carbs = food.getCarbsPer100g() != null ? food.getCarbsPer100g().doubleValue() : 0.0;
        double fiber = food.getFiberPer100g() != null ? food.getFiberPer100g().doubleValue() : 0.0;
        double calories = food.getCaloriesPer100g() != null ? food.getCaloriesPer100g().doubleValue() : 0.0;
        double healthScore = food.getHealthScore() != null ? food.getHealthScore().doubleValue() : 50.0;

        double score = healthScore;

        // Ưu tiên cộng +200 điểm thưởng nếu là món được khuyên dùng (is_recommended == true) hoặc tên món phổ biến
        if (Boolean.TRUE.equals(food.getIsRecommended()) || isPopularFoodForGoal(food, goalType)) {
            score += 200.0;
        }

        // Cộng điểm ưu tiên theo danh mục Rau củ (VEG) và Hoa quả (FRUIT) từ Database
        if (food.getCategory() != null && food.getCategory().getCode() != null) {
            String catCode = food.getCategory().getCode().toUpperCase();
            if ("VEG".equals(catCode) || "FRUIT".equals(catCode)) {
                score += 100.0;
            }
        }

        // Ưu tiên cộng điểm theo chế độ ăn (Diet Preference) dựa trên thành phần dinh dưỡng
        if (diets != null && !diets.isEmpty()) {
            for (UserDietPreference pref : diets) {
                if (pref.getDietTag() == null || pref.getDietTag().getName() == null) continue;
                String tag = pref.getDietTag().getName().toLowerCase();
                if (tag.contains("protein") || tag.contains("đạm")) {
                    score += protein * 5.0;
                } else if (tag.contains("keto")) {
                    score += (fat * 4.0) - (carbs * 3.0);
                } else if (tag.contains("low carb") || tag.contains("ít tinh bột") || tag.contains("ít carb")) {
                    score -= carbs * 2.0;
                } else if (tag.contains("low fat") || tag.contains("ít béo") || tag.contains("ít chất béo")) {
                    score -= fat * 2.0;
                } else if (tag.contains("fiber") || tag.contains("xơ") || tag.contains("chất xơ")) {
                    score += fiber * 5.0;
                }
            }
        }

        if (goalType == null) return score;

        return score + switch (goalType) {
            case "LOSE_0_5KG", "LOSE_1KG" -> (protein * 4.0) + (fiber * 5.0) - (calories * 0.1);
            case "GAIN_MUSCLE" -> (protein * 8.0) + (carbs * 1.5) - (fat * 0.5);
            case "GAIN_0_5KG", "GAIN_1KG" -> (protein * 4.0) + (calories * 0.2) + (carbs * 2.0);
            case "ENDURANCE" -> (carbs * 5.0) + (protein * 3.0) - (fat * 0.5);
            default -> (protein * 3.0) + (fiber * 3.0);
        };
    }

    private boolean isPopularFoodForGoal(Food food, String goalType) {
        if (food == null || food.getName() == null) return false;
        String name = food.getName().toLowerCase().trim();

        if (goalType != null) {
            String upperGoal = goalType.toUpperCase();
            if (upperGoal.contains("LOSE") || upperGoal.contains("CUTTING")) {
                List<String> cuttingKeywords = Arrays.asList(
                    "ức gà", "cá hồi", "cá trắng", "cá lóc", "cá diêu hồng", "bò nạc", "thịt bò", "đậu phụ", "đậu hũ",
                    "sữa chua hy lạp", "sữa chua", "whey", "yến mạch", "gạo lứt", "khoai lang", "quinoa", "sandwich nguyên cám",
                    "bánh mì nguyên cám", "táo", "cam", "kiwi", "dâu", "hạnh nhân", "óc chó", "salad", "rau", "cải", "súp lơ",
                    "bông cải", "dưa chuột", "cà chua", "bánh gạo"
                );
                if (cuttingKeywords.stream().anyMatch(name::contains)) return true;
            } else if (upperGoal.contains("GAIN_0") || upperGoal.contains("GAIN_1") || upperGoal.contains("BULKING")) {
                List<String> bulkingKeywords = Arrays.asList(
                    "ức gà", "thịt gà", "thịt bò", "bò nạc", "trứng", "cá hồi", "cá ngừ", "cá lóc", "cá diêu hồng",
                    "tôm", "hải sản", "thịt heo nạc", "thịt lợn nạc", "đậu phụ", "đậu hũ", "sữa chua hy lạp", "sữa chua", "whey",
                    "yến mạch", "bánh mì", "bánh mì nguyên cám", "cơm", "khoai lang", "chuối", "bún", "phở", "pancake",
                    "sandwich", "mì", "nui", "trái cây", "sinh tố", "sữa", "hạt", "hạnh nhân", "óc chó", "protein shake",
                    "rau", "cải", "súp lơ", "bông cải", "salad", "dưa chuột", "cà chua"
                );
                if (bulkingKeywords.stream().anyMatch(name::contains)) return true;
            } else if (upperGoal.contains("MUSCLE")) {
                List<String> muscleKeywords = Arrays.asList(
                    "ức gà", "thịt bò", "bò nạc", "trứng", "lòng trắng trứng", "cá hồi", "cá ngừ", "tôm", "hải sản",
                    "đậu phụ", "sữa chua hy lạp", "whey", "yến mạch", "gạo lứt", "khoai lang", "chuối", "bánh mì nguyên cám",
                    "rau", "cải", "súp lơ", "bông cải", "salad", "táo", "hạt"
                );
                if (muscleKeywords.stream().anyMatch(name::contains)) return true;
            } else if (upperGoal.contains("HEALTHY") || upperGoal.contains("EAT_CLEAN")) {
                List<String> healthyKeywords = Arrays.asList(
                    "yến mạch", "gạo lứt", "khoai lang", "quinoa", "bánh mì nguyên cám", "ức gà", "cá hồi", "cá nạc", "cá lóc",
                    "đậu phụ", "trứng", "táo", "kiwi", "cam", "bưởi", "dâu", "hạnh nhân", "óc chó", "hạt điều", "salad", "rau luộc",
                    "súp lơ", "bông cải", "dầu oliu", "sữa chua"
                );
                if (healthyKeywords.stream().anyMatch(name::contains)) return true;
            } else if (upperGoal.contains("ENDURANCE")) {
                List<String> enduranceKeywords = Arrays.asList(
                    "yến mạch", "gạo lứt", "cơm", "khoai lang", "mì", "nui", "chuối", "táo", "ức gà", "thịt bò", "cá", "trứng",
                    "sinh tố", "sữa", "hạt", "bánh mì", "phở", "bún", "rau"
                );
                if (enduranceKeywords.stream().anyMatch(name::contains)) return true;
            }
        }

        List<String> defaultPopularKeywords = Arrays.asList(
            "ức gà", "thịt gà", "thịt bò", "trứng", "cá hồi", "cá ngừ", "tôm", "cá", "đậu phụ", "sữa chua", "yến mạch",
            "cơm", "gạo lứt", "khoai lang", "bánh mì", "chuối", "táo", "cam", "bún", "phở", "mì", "nui", "rau", "salad", "hạt"
        );
        return defaultPopularKeywords.stream().anyMatch(name::contains);
    }

    private int getMaxCategoryLimit(String categoryCode, String goalType) {
        if (categoryCode == null) return 10;
        categoryCode = categoryCode.toUpperCase().trim();
        return switch (categoryCode) {
            case "VEG", "FRUIT", "MEAT", "SEAFOOD", "GRAIN", "DAIRY", "DRY_DISH", "NOODLE_SOUP" -> 30;
            case "BEVERAGE", "OILS", "SEASONING" -> 15;
            case "DESSERT", "FAST_FOOD" -> 10;
            default -> 20;
        };
    }

    private String translateActivityLevel(String level) {
        if (level == null) return null;
        return switch (level) {
            case "SEDENTARY" -> "Ít vận động (nhân viên văn phòng, ít tập thể dục)";
            case "LIGHTLY_ACTIVE" -> "Vận động nhẹ (tập thể dục 1-3 ngày/tuần)";
            case "MODERATELY_ACTIVE" -> "Vận động vừa phải (tập thể dục 3-5 ngày/tuần)";
            case "VERY_ACTIVE" -> "Vận động nhiều (tập thể thao nặng 6-7 ngày/tuần)";
            case "EXTRA_ACTIVE" -> "Vận động cực kỳ nhiều (vận động viên, công việc lao động rất nặng)";
            default -> level;
        };
    }

    private String translateBudget(String budget) {
        if (budget == null) return null;
        return switch (budget) {
            case "LOW" -> "Tiết kiệm / Học sinh - sinh viên";
            case "MEDIUM" -> "Trung bình / Phổ thông";
            case "HIGH" -> "Cao / Ưu tiên thực phẩm cao cấp hoặc organic";
            default -> budget;
        };
    }

    private String translateGoal(String goal) {
        if (goal == null) return null;
        return switch (goal) {
            case "MAINTAIN" -> "Duy trì cân nặng";
            case "LOSE_0_5KG" -> "Giảm cân chậm (0.5 kg/tuần)";
            case "LOSE_1KG" -> "Giảm cân nhanh (1.0 kg/tuần)";
            case "GAIN_0_5KG" -> "Tăng cân chậm (0.5 kg/tuần)";
            case "GAIN_1KG" -> "Tăng cân nhanh (1.0 kg/tuần)";
            case "GAIN_MUSCLE" -> "Tăng cơ giảm mỡ";
            case "HEALTHY_LIFESTYLE" -> "Lối sống lành mạnh, ăn sạch";
            case "ENDURANCE" -> "Tăng thể lực & sức bền";
            default -> goal;
        };
    }

    private String translateDislikeGroup(String group) {
        if (group == null) return null;
        return switch (group) {
            case "ORGAN_MEAT" -> "Nội tạng động vật";
            case "SEAFOOD" -> "Hải sản";
            case "SPICY_FOOD" -> "Đồ ăn cay";
            case "FRIED_FOOD" -> "Đồ chiên rán nhiều dầu mỡ";
            case "FAST_FOOD" -> "Thức ăn nhanh";
            case "SUGARY_FOOD" -> "Đồ ngọt, đường nhiều";
            case "PROCESSED_FOOD" -> "Thực phẩm chế biến sẵn (xúc xích, thịt nguội)";
            case "DAIRY_PRODUCTS" -> "Sữa và chế phẩm từ sữa";
            case "OTHER" -> "Thực phẩm khác";
            default -> group;
        };
    }
}
