package com.bodypilot.backend.service.impl.workout;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bodypilot.backend.model.dto.workout.ExerciseCandidate;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Component dedicated to building AI Workout Prompt strings.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WorkoutPromptBuilder {

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public String buildWorkoutPrompt(UserProfile profile, UserGoal goal, UserMetricHistory metric,
            List<UserInjury> injuries, List<ExerciseCandidate> candidates,
            LocalDate startDate, Integer days, String focusBodyPart) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tạo lịch tập luyện thể thao trong ").append(days).append(" ngày liên tiếp bắt đầu từ ngày ")
                .append(startDate)
                .append(" dựa trên thông tin người dùng và danh sách bài tập được cung cấp dưới đây:\n\n");

        if (profile != null) {
            sb.append("- Giới tính: ").append(profile.getGender() != null ? profile.getGender() : "Chưa cập nhật")
                    .append("\n");
            sb.append("- Tuổi: ").append(profile.getAge() != null ? profile.getAge() : "Chưa cập nhật").append("\n");
            sb.append("- Chiều cao: ")
                    .append(profile.getHeightCm() != null ? profile.getHeightCm() + " cm" : "Chưa cập nhật")
                    .append("\n");
            sb.append("- Cân nặng hiện tại: ")
                    .append(profile.getWeight() != null ? profile.getWeight() + " kg" : "Chưa cập nhật").append("\n");
            sb.append("- Mức độ hoạt động: ")
                    .append(profile.getActivityLevel() != null ? translateActivityLevel(profile.getActivityLevel())
                            : "Chưa cập nhật")
                    .append("\n");
            boolean isExperienced = Boolean.TRUE.equals(profile.getHasExperience());
            sb.append("- Kinh nghiệm tập luyện: ")
                    .append(isExperienced ? "Đã có kinh nghiệm tập luyện" : "Người mới bắt đầu (Chưa từng tập)")
                    .append("\n");
        }

        if (goal != null) {
            sb.append("- Mục tiêu thể hình: ").append(translateGoal(goal.getType())).append("\n");
            sb.append("- Cân nặng mục tiêu: ")
                    .append(goal.getTargetWeight() != null ? goal.getTargetWeight() + " kg" : "Chưa cập nhật")
                    .append("\n");
        }

        String focusText = (focusBodyPart != null && !focusBodyPart.trim().isEmpty()
                && !"NONE".equalsIgnoreCase(focusBodyPart) && !"KHÔNG CÓ".equalsIgnoreCase(focusBodyPart))
                        ? focusBodyPart
                        : "Không có";
        sb.append("- Bộ phận muốn tập chủ yếu: ").append(focusText).append("\n");

        if (injuries != null && !injuries.isEmpty()) {
            String injuryDetails = injuries.stream()
                    .map(i -> String.format("%s (Mức độ: %s)",
                            i.getInjury().getName(),
                            i.getSeverityOverride() != null ? i.getSeverityOverride()
                                    : i.getInjury().getSeverityLevel()))
                    .collect(Collectors.joining(", "));
            sb.append("- Chấn thương (BẮT BUỘC TRÁNH bài tập tác động xấu đến vùng này): ").append(injuryDetails)
                    .append("\n");
        }

        sb.append("\nDANH SÁCH BÀI TẬP ĐƯỢC PHÉP SỬ DỤNG TRONG DATABASE (CANDIDATES):\n");
        try {
            String jsonCandidates = objectMapper.writeValueAsString(candidates);
            sb.append(jsonCandidates).append("\n");
        } catch (Exception e) {
            sb.append("[]\n");
        }

        sb.append("\nYêu cầu định dạng đầu ra:\n");
        boolean isExperienced = profile != null && Boolean.TRUE.equals(profile.getHasExperience());
        if (!isExperienced) {
            sb.append("LƯU Ý QUAN TRỌNG VỀ ĐỘ KHÓ: Người dùng là NGƯỜI MỚI BẮT ĐẦU (Chưa từng tập).\n")
              .append("- Ưu tiên bài tập cơ bản, máy tập cố định hoặc bodyweight dễ thực hiện.\n")
              .append("- Số hiệp tập vừa phải (2 - 3 sets/bài), số lần lặp an toàn (10 - 15 reps), thời gian nghỉ đầy đủ (60 - 90 giây).\n")
              .append("- Mức tạ ban đầu nhẹ nhàng hoặc vừa sức.\n")
              .append("- Trong trường `notes`, hãy ghi chú ngắn gọn về kiểm soát nhịp thở, form chuẩn và an toàn khớp.\n\n");
        } else {
            sb.append("LƯU Ý QUAN TRỌNG VỀ ĐỘ KHÓ: Người dùng ĐÃ CÓ KINH NGHIỆM TẬP LUYỆN.\n")
              .append("- Thiết kế chương trình có tính tăng tiến (Progressive Overload), kết hợp bài tập phức hợp (Compound) và cô lập (Isolation).\n")
              .append("- Số hiệp 3 - 4 sets/bài, cường độ cao hơn, tối ưu áp lực kích thích phát triển cơ bắp/thể lực.\n\n");
        }

        sb.append(
                "Hãy tự thiết kế một lịch tập mới hoàn toàn sử dụng các bài tập trong danh sách ứng viên (CANDIDATES) ở trên để tạo lịch tập gợi ý trong ")
                .append(days).append(" ngày liên tiếp bắt đầu từ ngày ").append(startDate).append(".\n");
        sb.append(
                "RÀNG BUỘC CỐT LÕI: Bạn CHỈ ĐƯỢC CHỌN bài tập từ danh sách cung cấp ở trên. Bắt buộc phải khớp đúng UUID của bài tập trong trường `exerciseId`. KHÔNG tự ý tạo bài tập mới.\n");
        sb.append(
                "Không được phép thêm bất kỳ chữ giải thích nào khác ngoài chuỗi JSON hợp lệ. Vui lòng cung cấp định dạng JSON chuẩn xác theo cấu trúc sau:\n");
        sb.append("[\n");
        sb.append("  {\n");
        sb.append("    \"date\": \"YYYY-MM-DD\",\n");
        sb.append("    \"note\": \"Ghi chú ngày tập (ví dụ: Tập ngực & tay sau hoặc Ngày nghỉ ngơi phục hồi)\",\n");
        sb.append("    \"isAiGenerated\": true,\n");
        sb.append("    \"workoutItems\": [\n");
        sb.append("      {\n");
        sb.append("        \"orderIndex\": 0,\n");
        sb.append("        \"exerciseId\": \"UUID của bài tập được chọn\",\n");
        sb.append("        \"sets\": 4,\n");
        sb.append("        \"reps\": 12,\n");
        sb.append("        \"weightKg\": 10.0,\n");
        sb.append("        \"restSeconds\": 60,\n");
        sb.append("        \"durationMinutes\": 10,\n");
        sb.append("        \"distanceKm\": 0.0,\n");
        sb.append("        \"caloriesBurned\": 80.0,\n");
        sb.append("        \"notes\": \"Hướng dẫn thực hiện ngắn gọn cho bài tập này\"\n");
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
