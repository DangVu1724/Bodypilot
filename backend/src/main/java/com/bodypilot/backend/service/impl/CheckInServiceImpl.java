package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.checkin.CheckInRequest;
import com.bodypilot.backend.model.dto.checkin.CheckInResultResponse;
import com.bodypilot.backend.model.dto.checkin.CheckInStatusResponse;
import com.bodypilot.backend.model.dto.nutrition.CalorieCalculationResult;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.model.enums.Goal;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.CalorieCalculatorService;
import com.bodypilot.backend.service.CheckInService;
import com.bodypilot.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

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
    private final GeminiClient geminiClient;
    private final NotificationService notificationService;

    @Override
    public CheckInStatusResponse getCheckInStatus(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        UserProfile profile = profileRepository.findByUserId(userId)
                .orElse(null);

        UserCheckInHistory latestCheckIn = userCheckInHistoryRepository.findTopByUserIdOrderByCreatedAtDesc(userId).orElse(null);
        LocalDate lastCheckInDate = latestCheckIn != null ? latestCheckIn.getCheckInDate() : null;

        LocalDate today = LocalDate.now();
        java.time.DayOfWeek dayOfWeek = today.getDayOfWeek();
        boolean isSundayOrMonday = dayOfWeek == java.time.DayOfWeek.SUNDAY || dayOfWeek == java.time.DayOfWeek.MONDAY;

        LocalDate sundayOfThisWeek = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.SUNDAY));

        boolean checkedInThisWeek = userCheckInHistoryRepository.existsByUserIdAndCheckInDateBetween(userId, sundayOfThisWeek, today);

        // User is considered new if they have never checked in and registered within the last 7 days
        boolean hasNeverCheckedIn = (lastCheckInDate == null);
        LocalDate registrationDate = user.getCreatedAt() != null ? user.getCreatedAt().toLocalDate() : today;
        long daysSinceRegistration = ChronoUnit.DAYS.between(registrationDate, today);

        boolean onboardingNeeded = hasNeverCheckedIn && daysSinceRegistration < 7;
        boolean isDue = !onboardingNeeded && isSundayOrMonday && !checkedInThisWeek;

        long daysSinceLastCheckIn = lastCheckInDate != null ? ChronoUnit.DAYS.between(lastCheckInDate, today) : daysSinceRegistration;

        Double currentWeight = profile != null && profile.getWeight() != null ? profile.getWeight() : 60.0;
        Double currentHeight = profile != null && profile.getHeightCm() != null ? profile.getHeightCm() : 170.0;

        UserGoal activeGoal = goalRepository.findByUserIdAndStatus(userId, "ACTIVE")
                .stream().findFirst().orElse(null);
        String goalStr = activeGoal != null ? activeGoal.getType() : "LOSE_0_5KG";

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
        Double heightCm = request.getNewHeightCm() != null ? request.getNewHeightCm() : (profile.getHeightCm() != null ? profile.getHeightCm() : 170.0);

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
        String selectedGoalStr = hasNewGoal ? requestedGoal : (activeGoal != null ? activeGoal.getType() : "LOSE_0_5KG");

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
                newWeight, heightCm, age, genderEnum, activityEnum, goalEnum
        );

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
        String aiFeedback = generateAiCheckInFeedback(previousWeight, newWeight, weightChange, request, calculationResult);

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
            boolean hasNoInjuries = Boolean.FALSE.equals(request.getHasInjury()) || request.getInjuredParts() == null || request.getInjuredParts().isEmpty();

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
            notificationService.createNotification(userId, com.bodypilot.backend.model.dto.notification.CreateNotificationRequest.builder()
                    .title("Khảo sát Check-in tuần đã hoàn tất! 📊🎉")
                    .body("Chỉ số TDEE mới của bạn là " + Math.round(calculationResult.getTdee()) + " kcal/ngày. AI đã cập nhật nhận xét và kế hoạch phù hợp.")
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
        if (geminiClient.isApiKeyConfigured()) {
            try {
                String prompt = String.format(
                        "Người dùng vừa hoàn thành khảo sát check-in định kỳ:\n" +
                        "- Cân nặng trước: %.1f kg, Cân nặng mới: %.1f kg (Thay đổi: %+.1f kg)\n" +
                        "- Mức độ tuân thủ: %s, Thể trạng: %s, Mức độ đói: %s\n" +
                        "- TDEE mới: %.0f kcal, Calo mục tiêu mới: %.0f kcal\n\n" +
                        "Hãy viết một nhận xét ngắn (3-4 câu bằng tiếng Việt) đánh giá tiến độ của người dùng, đưa ra lời khuyên chân thành và truyền động lực cho tuần tiếp theo.",
                        prevWeight, newWeight, weightChange,
                        translateAdherence(request.getAdherenceLevel()),
                        translateEnergy(request.getEnergyLevel()),
                        translateHunger(request.getHungerLevel()),
                        calc.getTdee(), calc.getTargetCalories()
                );
                String systemInstruction = "Bạn là chuyên gia huấn luyện viên thể hình và dinh dưỡng AI cá nhân. Hãy đưa ra nhận xét ngắn gọn, chu đáo, tích cực và truyền cảm hứng.";
                return geminiClient.callGemini(prompt, systemInstruction);
            } catch (Exception e) {
                log.warn("Gemini AI call failed during check-in feedback, using fallback response: {}", e.getMessage());
            }
        }

        // Fallback feedback logic
        StringBuilder sb = new StringBuilder();
        if (weightChange < 0) {
            sb.append(String.format("Chúc mừng bạn đã giảm được %.1f kg trong chu kỳ vừa qua! ", Math.abs(weightChange)));
        } else if (weightChange > 0) {
            sb.append(String.format("Cân nặng của bạn đã tăng %.1f kg. ", weightChange));
        } else {
            sb.append("Cân nặng của bạn đang giữ mức ổn định tuyệt vời! ");
        }
        sb.append(String.format("Năng lượng tiêu thụ hàng ngày (TDEE) mới của bạn được điều chỉnh là %.0f kcal với mức calo mục tiêu %.0f kcal/ngày. Hãy giữ vững phong độ cho chu kỳ tiếp theo!", calc.getTdee(), calc.getTargetCalories()));

        return sb.toString();
    }

    private String translateGoal(String goalStr) {
        if (goalStr == null) return "Giảm cân nhẹ nhàng";
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

    private String translateAdherence(String val) {
        if (val == null) return "Khá tốt";
        return switch (val) {
            case "EXCELLENT" -> "Rất tốt (90-100%)";
            case "GOOD" -> "Khá tốt (70-80%)";
            case "NEEDS_WORK" -> "Cần cố gắng thêm (<50%)";
            default -> val;
        };
    }

    private String translateEnergy(String val) {
        if (val == null) return "Bình thường";
        return switch (val) {
            case "ENERGETIC" -> "Sung sức, tràn đầy năng lượng";
            case "NORMAL" -> "Bình thường, ổn định";
            case "TIRED" -> "Có mệt mỏi nhẹ";
            default -> val;
        };
    }

    private String translateHunger(String val) {
        if (val == null) return "Vừa đủ";
        return switch (val) {
            case "SATISFIED" -> "No đủ, thoải mái";
            case "NORMAL" -> "Bình thường";
            case "HUNGRY" -> "Nhanh đói";
            default -> val;
        };
    }
}
