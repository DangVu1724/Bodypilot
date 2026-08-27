package com.bodypilot.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.checkin.CheckInRequest;
import com.bodypilot.backend.model.dto.checkin.CheckInResultResponse;
import com.bodypilot.backend.model.dto.checkin.CheckInStatusResponse;
import com.bodypilot.backend.model.dto.nutrition.CalorieCalculationResult;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserCheckInHistory;
import com.bodypilot.backend.model.entity.user.UserGoal;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.user.UserMetricHistory;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.repository.InjuryRepository;
import com.bodypilot.backend.repository.UserCheckInHistoryRepository;
import com.bodypilot.backend.repository.UserGoalRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.repository.UserMetricHistoryRepository;
import com.bodypilot.backend.repository.UserProfileRepository;
import com.bodypilot.backend.repository.UserRepository;
import com.bodypilot.backend.service.CalorieCalculatorService;
import com.bodypilot.backend.service.CheckInService;
import com.bodypilot.backend.service.NotificationService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class CheckInServiceImpl implements CheckInService {

    private final UserRepository userRepository;
    private final UserProfileRepository profileRepository;
    private final UserGoalRepository goalRepository;
    private final UserMetricHistoryRepository metricHistoryRepository;
    private final UserCheckInHistoryRepository userCheckInHistoryRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final InjuryRepository injuryRepository;
    private final CalorieCalculatorService calorieCalculatorService;
    private final NotificationService notificationService;

    @Override
    public CheckInStatusResponse getCheckInStatus(UUID userId) {
        // 1. Truy vấn thông tin người dùng & hồ sơ cơ bản
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng với ID: " + userId));
        UserProfile profile = profileRepository.findByUserId(userId).orElse(null);

        // 2. Lấy thông tin lần check-in gần nhất
        UserCheckInHistory latestCheckIn = userCheckInHistoryRepository
                .findTopByUserIdOrderByCreatedAtDesc(userId).orElse(null);
        LocalDate lastCheckInDate = latestCheckIn != null ? latestCheckIn.getCheckInDate() : null;

        // 3. Tính toán thời gian & kiểm tra điều kiện Check-in tuần
        LocalDate today = LocalDate.now();
        boolean isSundayOrMonday = today.getDayOfWeek() == java.time.DayOfWeek.SUNDAY 
                || today.getDayOfWeek() == java.time.DayOfWeek.MONDAY;
        
        LocalDate sundayThisWeek = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.SUNDAY));
        boolean checkedInThisWeek = userCheckInHistoryRepository.existsByUserIdAndCheckInDateBetween(userId, sundayThisWeek, today);

        // 4. Xác định trạng thái tài khoản mới (Onboarding) & Hạn Check-in (isDue)
        LocalDate registrationDate = user.getCreatedAt() != null ? user.getCreatedAt().toLocalDate() : today;
        long daysSinceRegistration = ChronoUnit.DAYS.between(registrationDate, today);

        boolean onboardingNeeded = (lastCheckInDate == null) && (daysSinceRegistration < 7);
        boolean isDue = !onboardingNeeded && isSundayOrMonday && !checkedInThisWeek;
        long daysSinceLastCheckIn = lastCheckInDate != null ? ChronoUnit.DAYS.between(lastCheckInDate, today) : daysSinceRegistration;

        // 5. Lấy mục tiêu hoạt động & thông số thể trạng hiện tại
        Double currentWeight = (profile != null && profile.getWeight() != null) ? profile.getWeight() : 60.0;
        Double currentHeight = (profile != null && profile.getHeightCm() != null) ? profile.getHeightCm() : 170.0;

        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        String goalStr = activeGoal != null ? activeGoal.getType() : "LOSE_0_5KG";

        // 6. Trả về DTO kết quả trạng thái Check-in
        return CheckInStatusResponse.builder()
                .isCheckInDue(isDue)
                .onboardingNeeded(onboardingNeeded)
                .lastCheckInDate(lastCheckInDate)
                .daysSinceLastCheckIn(daysSinceLastCheckIn)
                .currentWeight(currentWeight)
                .currentHeightCm(currentHeight)
                .currentGoal(goalStr)
                .goalDescription(translateGoal(goalStr))
                .build();
    }

    @Override
    @Transactional
    public CheckInResultResponse submitCheckIn(UUID userId, CheckInRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        UserProfile profile = profileRepository.findByUserId(userId)
                .orElseGet(() -> profileRepository.save(UserProfile.builder().user(user).build()));

        Double previousWeight = profile.getWeight() != null ? profile.getWeight() : request.getNewWeight();
        Double newWeight = request.getNewWeight() != null ? request.getNewWeight() : previousWeight;
        Double heightCm = request.getNewHeightCm() != null ? request.getNewHeightCm()
                : (profile.getHeightCm() != null ? profile.getHeightCm() : 170.0);

        profile.setWeight(newWeight);
        if (request.getNewHeightCm() != null) {
            profile.setHeightCm(request.getNewHeightCm());
        }
        profileRepository.save(profile);

        // Update Goal if requested
        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);

        String requestedGoal = request.getGoalChoice();
        boolean hasNewGoal = requestedGoal != null && !"KEEP_SAME".equalsIgnoreCase(requestedGoal);
        String selectedGoalStr = hasNewGoal ? requestedGoal
                : (activeGoal != null ? activeGoal.getType() : "LOSE_0_5KG");

        if (hasNewGoal && activeGoal != null) {
            activeGoal.setType(selectedGoalStr);
            if (request.getTargetWeight() != null) {
                activeGoal.setTargetWeight(request.getTargetWeight());
            }
            goalRepository.save(activeGoal);
        }

        // Map Enums for Calorie Calculation
        Gender genderEnum = "Nam".equalsIgnoreCase(profile.getGender()) ? Gender.MALE : Gender.FEMALE;
        ActivityLevel activityEnum;
        try {
            activityEnum = ActivityLevel.valueOf(profile.getActivityLevel());
        } catch (Exception e) {
            activityEnum = ActivityLevel.SEDENTARY;
        }

        Goal goalEnum;
        try {
            goalEnum = Goal.valueOf(selectedGoalStr);
        } catch (Exception e) {
            goalEnum = Goal.LOSE_0_5KG;
        }

        int age = profile.getAge() != null ? profile.getAge() : 25;

        CalorieCalculationResult calculationResult = calorieCalculatorService.calculateMetrics(
                newWeight, heightCm, age, genderEnum, activityEnum, goalEnum);

        // Save new UserMetricHistory
        UserMetricHistory newMetric = UserMetricHistory.builder()
                .user(user)
                .weight(newWeight)
                .heightCm(heightCm)
                .age(age)
                .goal(selectedGoalStr)
                .activityLevel(activityEnum.name())
                .bmi(calculationResult.getBmi())
                .bmr(calculationResult.getBmr())
                .tdee(calculationResult.getTdee())
                .targetCalories(calculationResult.getTargetCalories())
                .build();
        metricHistoryRepository.save(newMetric);

        double weightChange = BigDecimal.valueOf(newWeight - previousWeight)
                .setScale(2, RoundingMode.HALF_UP)
                .doubleValue();

        // Generate AI Feedback
        String aiFeedback = generateAiCheckInFeedback(previousWeight, newWeight, weightChange, request,
                calculationResult);

        // Save UserCheckInHistory
        String injuredPartsStr = (request.getInjuredParts() != null && !request.getInjuredParts().isEmpty())
                ? String.join(",", request.getInjuredParts())
                : null;

        UserCheckInHistory checkInHistory = UserCheckInHistory.builder()
                .user(user)
                .checkInDate(LocalDate.now())
                .weight(newWeight)
                .heightCm(heightCm)
                .adherenceLevel(request.getAdherenceLevel())
                .energyLevel(request.getEnergyLevel())
                .hungerLevel(request.getHungerLevel())
                .workoutState(request.getWorkoutState())
                .hasInjury(request.getHasInjury())
                .injuredParts(injuredPartsStr)
                .goalChoice(selectedGoalStr)
                .targetWeight(request.getTargetWeight())
                .notes(request.getNotes())
                .newBmr(calculationResult.getBmr())
                .newTdee(calculationResult.getTdee())
                .newTargetCalories(calculationResult.getTargetCalories())
                .aiFeedback(aiFeedback)
                .build();
        userCheckInHistoryRepository.save(checkInHistory);

        // Sync UserInjuries in database (Optimized Batch Sync)
        if (request.getHasInjury() != null) {
            List<UserInjury> existingInjuries = userInjuryRepository.findAllByUserId(userId);
            boolean hasNoInjuries = Boolean.FALSE.equals(request.getHasInjury()) || request.getInjuredParts() == null
                    || request.getInjuredParts().isEmpty();

            if (hasNoInjuries) {
                if (!existingInjuries.isEmpty()) {
                    userInjuryRepository.deleteAll(existingInjuries);
                }
            } else {
                List<String> selectedCodes = request.getInjuredParts();

                // 1. Batch Delete injuries that are no longer selected
                List<UserInjury> toDelete = existingInjuries.stream()
                        .filter(u -> u.getInjury() != null && !selectedCodes.contains(u.getInjury().getCode()))
                        .toList();
                if (!toDelete.isEmpty()) {
                    userInjuryRepository.deleteAll(toDelete);
                }

                // 2. Batch Insert new injuries that do not exist in DB yet
                Set<String> existingCodes = existingInjuries.stream()
                        .filter(u -> u.getInjury() != null)
                        .map(u -> u.getInjury().getCode().toUpperCase())
                        .collect(Collectors.toSet());

                List<String> newCodes = selectedCodes.stream()
                        .filter(code -> !existingCodes.contains(code.toUpperCase()))
                        .toList();

                if (!newCodes.isEmpty()) {
                    List<UserInjury> newInjuries = newCodes.stream()
                            .map(code -> injuryRepository.findByCode(code).orElse(null))
                            .filter(Objects::nonNull)
                            .map(injury -> UserInjury.builder()
                                    .user(user)
                                    .injury(injury)
                                    .recoveryStatus(com.bodypilot.backend.model.enums.RecoveryStatus.RECOVERING)
                                    .build())
                            .toList();
                    if (!newInjuries.isEmpty()) {
                        userInjuryRepository.saveAll(newInjuries);
                    }
                }
            }
        }

        try {
            notificationService.createNotification(userId,
                    com.bodypilot.backend.model.dto.notification.CreateNotificationRequest.builder()
                            .title("Khảo sát Check-in tuần đã hoàn tất! 📊🎉")
                            .body("Chỉ số TDEE mới của bạn là " + Math.round(calculationResult.getTdee())
                                    + " kcal/ngày. AI đã cập nhật nhận xét và kế hoạch phù hợp.")
                            .category("CHECKIN")
                            .build());
        } catch (Exception e) {
            log.warn("Failed to create notification on check-in submit: {}", e.getMessage());
        }

        return CheckInResultResponse.builder()
                .previousWeight(previousWeight)
                .newWeight(newWeight)
                .weightChange(weightChange)
                .newBmr(calculationResult.getBmr())
                .newTdee(calculationResult.getTdee())
                .newTargetCalories(calculationResult.getTargetCalories())
                .aiFeedback(aiFeedback)
                .advice("Tiếp tục duy trì thói quen ăn uống và tập luyện để đạt được kết quả mục tiêu tốt nhất!")
                .build();
    }

    private String generateAiCheckInFeedback(Double prevWeight, Double newWeight, double weightChange,
            CheckInRequest request, CalorieCalculationResult calc) {
        StringBuilder sb = new StringBuilder();

        // 1. Phân tích xu hướng biến động cân nặng
        if (weightChange < -0.1) {
            double absChange = Math.abs(weightChange);
            if (absChange >= 0.3 && absChange <= 1.0) {
                sb.append(String.format(
                        "Chúc mừng bạn! Cân nặng đã giảm %.1f kg theo tốc độ an toàn và khoa học (0.5 - 1 kg/tuần). ",
                        absChange));
            } else if (absChange > 1.0) {
                sb.append(String.format(
                        "Bạn đã giảm %.1f kg trong tuần qua. Tốc độ này khá nhanh, hãy chú ý nạp đủ protein để bảo toàn khối lượng cơ bắp. ",
                        absChange));
            } else {
                sb.append(
                        String.format("Cân nặng của bạn giảm nhẹ %.1f kg, tiến trình đang đi đúng hướng! ", absChange));
            }
        } else if (weightChange > 0.1) {
            if (weightChange >= 0.3 && weightChange <= 0.8) {
                sb.append(String.format(
                        "Cân nặng tăng %.1f kg, rất phù hợp với tiến trình phát triển cơ bắp và thể trạng. ",
                        weightChange));
            } else {
                sb.append(String.format("Cân nặng của bạn đã tăng %.1f kg so với chu kỳ trước. ", weightChange));
            }
        } else {
            sb.append("Cân nặng của bạn đang giữ ở mức duy trì rất ổn định! ");
        }

        // 2. Phân tích chỉ số Calo & TDEE theo công thức Mifflin-St Jeor chuẩn khoa học
        sb.append(String.format(
                "Dựa trên chỉ số sinh học mới (BMR: %.0f kcal, TDEE: %.0f kcal), mục tiêu calo mỗi ngày được điều chỉnh là %.0f kcal/ngày. ",
                calc.getBmr(), calc.getTdee(), calc.getTargetCalories()));

        // 3. Đánh giá tình trạng thể trạng & chấn thương
        if (Boolean.TRUE.equals(request.getHasInjury()) && request.getInjuredParts() != null
                && !request.getInjuredParts().isEmpty()) {
            sb.append(
                    "Hệ thống đã ghi nhận tình trạng chấn thương và tự động loại bỏ các bài tập có rủi ro cho các vùng bị ảnh hưởng. ");
        } else if ("ENERGETIC".equalsIgnoreCase(request.getEnergyLevel())) {
            sb.append("Tuần qua bạn tràn đầy năng lượng, hãy tiếp tục duy trì nhịp độ thể lực tuyệt vời này nhé! ");
        } else if ("TIRED".equalsIgnoreCase(request.getEnergyLevel())) {
            sb.append("Bạn ghi nhận có dấu hiệu mệt mỏi; hãy chú ý nghỉ ngơi, ngủ đủ 7-8 tiếng và uống đủ nước. ");
        }

        sb.append("Hãy giữ vững phong độ cho tuần tiếp theo!");
        return sb.toString();
    }

    private String translateGoal(String goalStr) {
        if (goalStr == null)
            return "Giảm cân nhẹ nhàng";
        return switch (goalStr) {
            case "LOSE_0_5KG" -> "Giảm 0.5kg / tuần";
            case "LOSE_1KG" -> "Giảm 1kg / tuần";
            case "MAINTAIN" -> "Duy trì cân nặng";
            case "GAIN_0_5KG" -> "Tăng 0.5kg / tuần";
            case "GAIN_1KG" -> "Tăng 1kg / tuần";
            case "GAIN_MUSCLE" -> "Tăng cơ giảm mỡ";
            default -> goalStr;
        };
    }
}
