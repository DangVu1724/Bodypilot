package com.bodypilot.backend.service.impl.diet;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.nutrition.FoodCandidate;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.service.CalorieCalculatorService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Component dedicated to building AI Diet Prompt strings with Vietnamese
 * cultural food context.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DietPromptBuilder {

        private final CalorieCalculatorService calorieCalculatorService;
        private final ObjectMapper objectMapper = new ObjectMapper()
                        .registerModule(new JavaTimeModule())
                        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

        public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                        List<UserAllergy> allergies, List<UserDietPreference> diets,
                        List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate,
                        Integer days) {
                return buildPrompt(profile, goal, metric, allergies, diets, dislikes, candidates, startDate, days,
                                null);
        }

        public String buildPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
                        List<UserAllergy> allergies, List<UserDietPreference> diets,
                        List<UserFoodPreference> dislikes, List<FoodCandidate> candidates, LocalDate startDate,
                        Integer days,
                        String userFeedback) {
                StringBuilder sb = new StringBuilder();
                sb.append("Tạo kế hoạch dinh dưỡng gợi ý trong ").append(days)
                                .append(" ngày liên tiếp bắt đầu từ ngày ")
                                .append(startDate)
                                .append(" dựa trên thông tin người dùng và danh sách thực phẩm được cung cấp dưới đây:\n\n");

                if (profile != null) {
                        sb.append("- Giới tính: ")
                                        .append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật")
                                        .append("\n");
                        sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật")
                                        .append("\n");
                        sb.append("- Chiều cao: ")
                                        .append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm"
                                                        : "Chưa cập nhật")
                                        .append("\n");
                        sb.append("- Cân nặng hiện tại: ")
                                        .append(profile.getWeight() != null ? profile.getWeight() + " kg"
                                                        : "Chưa cập nhật")
                                        .append("\n");
                        sb.append("- Mức độ hoạt động: ")
                                        .append(profile.getActivityLevel() != null
                                                        ? translateActivityLevel(profile.getActivityLevel())
                                                        : "Chưa cập nhật")
                                        .append("\n");
                }

                if (goal != null) {
                        sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
                        sb.append("- Cân nặng mục tiêu: ")
                                        .append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg"
                                                        : "Chưa cập nhật")
                                        .append("\n");
                }

                if (metric != null && metric.getTargetCalories() != null && metric.getTargetCalories() > 0) {
                        double targetCal = metric.getTargetCalories();
                        Goal goalEnum = null;
                        if (goal != null && goal.getType() != null) {
                                try {
                                        goalEnum = Goal.valueOf(goal.getType().toUpperCase());
                                } catch (Exception ignored) {
                                }
                        }
                        CalorieCalculatorService.MacroRatio macros = calorieCalculatorService.getMacroRatio(goalEnum);
                        double targetP = Math.round((targetCal * macros.proteinRatio()) / 4.0);
                        double targetF = Math.round((targetCal * macros.fatRatio()) / 9.0);
                        double targetC = Math.round((targetCal * macros.carbsRatio()) / 4.0);

                        sb.append("- Nhu cầu năng lượng mục tiêu hàng ngày (BẮT BUỘC ĐẠT ĐƯỢC TRONG 3 BỮA):\n");
                        sb.append(String.format("  + Tổng Calo mục tiêu: %.0f kcal/ngày\n", targetCal));
                        sb.append(String.format("  + Đạm (Protein) mục tiêu: ~%.0f g/ngày (%.0f%% calo)\n", targetP,
                                        macros.proteinRatio() * 100));
                        sb.append(String.format("  + Tinh bột (Carbs) mục tiêu: ~%.0f g/ngày (%.0f%% calo)\n", targetC,
                                        macros.carbsRatio() * 100));
                        sb.append(String.format("  + Chất béo (Fat) mục tiêu: ~%.0f g/ngày (%.0f%% calo)\n", targetF,
                                        macros.fatRatio() * 100));
                }

                if (allergies != null && !allergies.isEmpty()) {
                        String allergyList = allergies.stream()
                                        .map(a -> a.getAllergyMaster() != null ? a.getAllergyMaster().getName()
                                                        : a.getNote())
                                        .filter(s -> s != null && !s.isEmpty())
                                        .collect(Collectors.joining(", "));
                        sb.append("- Dị ứng thực phẩm (BẮT BUỘC TRÁNH KHỎI THỰC ĐƠN): ").append(allergyList)
                                        .append("\n");
                }

                if (diets != null && !diets.isEmpty()) {
                        String dietList = diets.stream()
                                        .map(d -> d.getDietTag() != null ? d.getDietTag().getName() : "")
                                        .filter(s -> !s.isEmpty())
                                        .collect(Collectors.joining(", "));
                        sb.append("- Chế độ ăn kiêng ưu tiên: ").append(dietList).append("\n");
                }

                if (dislikes != null && !dislikes.isEmpty()) {
                        String dislikeList = dislikes.stream()
                                        .map(d -> (d.getNote() != null && !d.getNote().trim().isEmpty()) ? d.getNote()
                                                        : (d.getDislikedFoodGroup() != null
                                                                        ? d.getDislikedFoodGroup().name()
                                                                        : ""))
                                        .filter(s -> !s.isEmpty())
                                        .distinct()
                                        .collect(Collectors.joining(", "));
                        sb.append("- Thực phẩm hạn chế(Ưu tiên tối đa hạn chế hoặc tránh đưa vào thực đơn): ")
                                        .append(dislikeList).append("\n");
                }

                if (userFeedback != null && !userFeedback.trim().isEmpty()) {
                        sb.append("\nGHI CHÚ / YÊU CẦU ĐẶC BIỆT TỪ NGƯỜI DÙNG CHO LẦN TẠO NÀY:\n");
                        sb.append("\"").append(userFeedback.trim()).append("\"\n");
                        sb.append(
                                        "Hãy điều chỉnh thực đơn phù hợp với yêu cầu trên, nhưng vẫn tuân thủ các quy tắc dị ứng và danh sách ứng viên bên dưới.\n");
                }

                sb.append("\nDANH SÁCH THỰC PHẨM ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
                try {
                        String jsonCandidates = objectMapper.writeValueAsString(candidates);
                        sb.append(jsonCandidates).append("\n");
                } catch (Exception e) {
                        sb.append("[]\n");
                }

                String goalCode = (goal != null && goal.getType() != null) ? goal.getType().toUpperCase() : "MAINTAIN";

                sb.append("\nQUY TẮC CỐT LÕI VĂN HÓA ẨM THỰC VIỆT NAM VÀ DINH DƯỠNG (BẮT BUỘC TUÂN THỦ NGHIÊM NGẶT):\n");
                sb.append(
                                "1. RÀNG BUỘC SỐ BỮA: Mỗi ngày BẮT BUỘC CHỈ TẠO ĐÚNG 3 BỮA CHÍNH: BREAKFAST (Bữa sáng), LUNCH (Bữa trưa), DINNER (Bữa tối). TUYỆT ĐỐI KHÔNG TẠO THÊM BẤT KỲ MEAL SLOT NÀO KHÁC.\n");
                sb.append("2. CẤU TRÚC BỮA SÁNG (BREAKFAST) - BẮT BUỘC TỪ 2 ĐẾN 3 MÓN PHỐI HỢP PHÙ HỢP VÀ CHUẨN THỰC TẾ:\n");
                sb.append(
                                "   - Bữa sáng BẮT BUỘC gồm từ 2 đến 3 món ăn được phối hợp tự nhiên, đa dạng và thực tế (như các combo điểm tâm chuẩn):\n");
                sb.append(
                                "     + COMBO MÓN NƯỚC: 1 Món nước (`NOODLE_SOUP` như Phở, Bún bò, Cháo...) + 1 Đồ uống (`BEVERAGE`/`DAIRY` như Sữa tươi, Sữa chua, Cà phê) HOẶC 1 phần Trái cây.\n");
                sb.append(
                                "     + COMBO BÁNH MÌ & SANDWICH: Bánh mì nguyên cám / Bánh mì cám yến mạch / Sandwich / French Toast (`GRAIN`/`DRY_DISH`) + 1 Món đạm nhẹ (Trứng gà ốp la/luộc, Thịt nguội) + 1 Đồ uống/Sinh tố (Sinh tố bơ, Sữa tươi, Cà phê) HOẶC 1 quả Trái cây (Chuối, Táo).\n");
                sb.append(
                                "     + COMBO YẾN MẠCH & SỮA CHUA: Yến mạch / Sữa chua Hy Lạp + Hạt / Trái cây + Trứng luộc / Sữa.\n");
                sb.append(
                                "   - BẮT BUỘC TRONG TUẦN: Bắt buộc phải có ít nhất 1 ngày Bữa sáng là COMBO MÓN NƯỚC (như Phở, Bún bò, Hủ tiếu hoặc Cháo).\n");
                sb.append(
                                "   - TUYỆT ĐỐI CẤM ĐƯA CÁC MÓN MẶN ĂN CƠM TRƯA/TỐI VÀO BỮA SÁNG: Cấm đưa các món mặn mâm cơm như Đậu phụ chiên, Rau củ xào, Thịt kho, Cá nướng, Thịt xào... vào Bữa sáng!\n");
                sb.append("3. CẤU TRÚC BỮA TRƯA & BỮA TỐI (LUNCH & DINNER) - CHUẨN MÂM CƠM VIỆT NAM:\n");
                sb.append(
                                "   - Bữa trưa và Bữa tối phải được phối hợp chuẩn mâm cơm Việt Nam: 1 Món cơm (Cơm trắng hoặc Cơm gạo lứt) + 1 Món mặn giàu đạm chính + 1 Món Rau / Canh thanh mát.\n");
                sb.append(
                                "   - Bữa tối BẮT BUỘC trong danh sách `items` phải chứa 1 món CƠM ĐÃ NẤU (Cơm trắng hoặc Cơm gạo lứt) làm tinh bột chính, ăn kèm 1 món mặn quen thuộc và rau củ/canh.\n");
                sb.append(
                                "   - TUYỆT ĐỐI KHÔNG xếp 2 món mặn nướng / khó tiêu trong cùng 1 bữa (Ví dụ: KHÔNG ĐƯỢC kết hợp Cá nướng + Dê nướng trong cùng 1 bữa trưa).\n");
                sb.append(
                                "   - Ưu tiên chọn các món ăn dân dã, quen thuộc với người Việt. Tránh kết hợp các món xa lạ hoặc kỳ lạ.\n");
                sb.append("4. QUY TẮC TRÁI CÂY TRÁNG MIỆNG (FRUITS):\n");
                sb.append(
                                "   - LƯỢNG TRÁI CÂY VỪA PHẢI: Mỗi ngày CHỈ NÊN CÓ TỪ 1 ĐẾN 2 PHẦN TRÁI CÂY TỔNG CỘNG (Ưu tiên phần lớn các ngày chỉ cần 1 loại trái cây làm món tráng miệng ở Bữa trưa hoặc Bữa tối; KHÔNG NÊN ngày nào cũng xếp cả 2 bữa đều có trái cây).\n");
                sb.append(
                                "   - NẾU MỘT NGÀY CÓ 2 BỮA CÓ TRÁI CÂY: Hai loại trái cây ở 2 bữa đó BẮT BUỘC PHẢI KHÁC NHAU (Ví dụ: Bữa trưa ăn Táo thì Bữa tối ăn Dưa hấu hoặc Chuối; TUYỆT ĐỐI KHÔNG chọn cùng 1 loại trái cây cho 2 bữa trong cùng một ngày).\n");
                sb.append(
                                "   - Trong mỗi bữa ăn, CHỈ ĐƯỢC chọn tối đa 1 phần / 1 loại trái cây duy nhất làm món tráng miệng hoặc ăn kèm.\n");
                sb.append("5. CHIẾN LƯỢC DINH DƯỠNG THEO MỤC TIÊU THỂ HÌNH:\n");

                if (goalCode.contains("LOSE") || goalCode.contains("CUTTING")) {
                        sb.append("   - MỤC TIÊU GIẢM CÂN / SIẾT MỠ (LOSE / CUTTING):\n");
                        sb.append("     + Tinh bột: Ưu tiên gạo lứt, yến mạch, khoai lang. Bữa tối giảm 50% lượng cơm so với bữa trưa.\n");
                        sb.append("     + Đạm: Ưu tiên các nguồn đạm nạc, chế biến thanh đạm (hấp, luộc, áp chảo ít dầu). Hạn chế món chiên rán nhiều dầu mỡ.\n");
                        sb.append("     + Chất xơ: Tăng cường định lượng rau xanh và canh để no lâu và hỗ trợ tiêu hóa.\n");
                } else if (goalCode.contains("GAIN_0") || goalCode.contains("GAIN_1") || goalCode.contains("BULKING")) {
                        sb.append("   - MỤC TIÊU TĂNG CÂN / TĂNG CƠ (BULKING / GAIN):\n");
                        sb.append("     + Năng lượng & Tinh bột: Đảm bảo khẩu phần cơm và tinh bột đầy đủ trong cả 3 bữa để thặng dư calo.\n");
                        sb.append("     + Đạm: Cung cấp lượng đạm dồi dào và đa dạng trong tất cả các bữa chính.\n");
                        sb.append("     + Kết hợp: Linh hoạt bổ sung thêm sữa, sinh tố hoặc trái cây giàu năng lượng để đạt calo mục tiêu.\n");
                } else if (goalCode.contains("MUSCLE")) {
                        sb.append("   - MỤC TIÊU TĂNG CƠ GIẢM MỠ (MUSCLE RECOMPOSITION):\n");
                        sb.append("     + Đạm: Tối đa hóa mật độ protein nạc trong mỗi bữa ăn để phục hồi và phát triển cơ bắp.\n");
                        sb.append("     + Tinh bột: Sử dụng tinh bột hấp thu chậm với định lượng vừa phải, phân bổ đều trong ngày.\n");
                } else if (goalCode.contains("HEALTHY") || goalCode.contains("EAT_CLEAN")) {
                        sb.append("   - MỤC TIÊU ĂN CLEAN / SỨC KHỎE (HEALTHY LIFESTYLE):\n");
                        sb.append("     + Chế biến: Ưu tiên thực phẩm nguyên bản, phương pháp hấp, luộc, nướng thanh đạm, ít gia vị công nghiệp.\n");
                        sb.append("     + Đa dạng: Phối hợp phong phú các nhóm thực phẩm tươi và rau củ tự nhiên.\n");
                } else {
                        sb.append("   - MỤC TIÊU DUY TRÌ THỂ TRẠNG & SỨC KHỎE (MAINTAIN):\n");
                        sb.append("     + Cân bằng: Tỷ lệ đạm, tinh bột, chất béo và chất xơ hài hòa theo mâm cơm chuẩn hàng ngày.\n");
                }

                sb.append(
                                "6. ĐA DẠNG MÓN ĂN: Tuyệt đối không lặp lại cùng một món quá 2 lần trong tuần. Hãy xoay vòng đa dạng giữa các ngày.\n");
                sb.append(
                                "7. ĐỊNH LƯỢNG KHẨU PHẦN TỰ NHIÊN VÀ ĐA DẠNG (`servingQuantity`):\n" +
                                                "   - Hãy tự do tính toán định lượng khẩu phần `servingQuantity` linh hoạt và thực tế theo đúng bản chất từng món ăn (Ví dụ: 1 tô Phở/Bún khoảng 350g-450g; 1 bát Cơm 150g-220g; Ức gà/Cá/Thịt 120g-180g; Trứng 50g-100g; Trái cây 120g-200g; Canh/Rau 130g-200g).\n"
                                                +
                                                "   - Định lượng giữa các món phải tự nhiên, phong phú và đa dạng. TUYỆT ĐỐI KHÔNG để tất cả món đều là con số mặc định rập khuôn như 100g hay 80g!\n");

                sb.append("\nYêu cầu định dạng đầu ra:\n");
                sb.append("Bạn PHẦI trả về một JSON array duy nhất đại diện cho thực đơn gợi ý của ").append(days)
                                .append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
                sb.append(
                                "RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN thực phẩm từ danh sách Candidates ở trên. Bắt buộc phải khớp đúng UUID của thực phẩm đó trong trường `foodId`.\n");
                sb.append("BẮT BUỘC HOÀN THÀNH ĐẦY ĐỦ: Bạn PHẢI sinh đầy đủ cả 3 bữa (BREAKFAST, LUNCH, DINNER) cho tất cả ")
                                .append(days)
                                .append(" ngày! TUYỆT ĐỐI KHÔNG DỪNG LẠI GIỮA CHỪNG HAY CẮT BỚT BỮA TRƯA/TỐI!\n");
                sb.append(
                                "Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
                sb.append("[\n");
                sb.append("  {\n");
                sb.append("    \"date\": \"YYYY-MM-DD\",\n");
                sb.append("    \"note\": \"...\",\n");
                sb.append("    \"isAiGenerated\": true,\n");
                sb.append("    \"mealSlots\": [\n");
                sb.append("      {\n");
                sb.append("        \"mealType\": \"BREAKFAST\",\n");
                sb.append("        \"customName\": \"Bữa sáng\",\n");
                sb.append("        \"orderIndex\": 0,\n");
                sb.append("        \"items\": [\n");
                sb.append("          {\n");
                sb.append("            \"foodId\": \"UUID\",\n");
                sb.append("            \"foodName\": \"Tên thực phẩm\",\n");
                sb.append("            \"servingQuantity\": 150.0\n");
                sb.append("          }\n");
                sb.append("        ]\n");
                sb.append("      }\n");
                sb.append("    ]\n");
                sb.append("  }\n");
                sb.append("]\n");

                return sb.toString();
        }

        private String translateActivityLevel(String level) {
                if (level == null)
                        return "Vừa phải";
                return switch (level.toUpperCase()) {
                        case "SEDENTARY" -> "Ít vận động (Ngồi nhiều, ít tập thể thao)";
                        case "LIGHTLY_ACTIVE" -> "Vận động nhẹ (Tập nhẹ 1-3 ngày/tuần)";
                        case "MODERATELY_ACTIVE" -> "Vận động vừa (Tập 3-5 ngày/tuần)";
                        case "VERY_ACTIVE" -> "Vận động nhiều (Tập 6-7 ngày/tuần)";
                        case "EXTRA_ACTIVE" -> "Vận động rất nhiều (Tập nặng, lao động chân tay)";
                        default -> level;
                };
        }

        private String translateGoal(String goal) {
                if (goal == null)
                        return "Duy trì vóc dáng";
                return switch (goal.toUpperCase()) {
                        case "LOSE_WEIGHT", "LOSE_0_5KG", "LOSE_1KG" -> "Giảm cân / Giảm mỡ";
                        case "GAIN_MUSCLE", "GAIN_0_5KG", "GAIN_1KG" -> "Tăng cơ / Tăng cân";
                        case "MAINTAIN" -> "Duy trì cân nặng & Sức khỏe";
                        case "ENDURANCE" -> "Tăng thể lực & Sức bền";
                        default -> goal;
                };
        }
}
