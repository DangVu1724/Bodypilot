package com.bodypilot.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapRequest;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapRequest;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserInjury;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.model.enums.FoodType;
import com.bodypilot.backend.repository.ExerciseRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.UserAllergyRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.service.SmartSwapService;
import com.bodypilot.backend.service.impl.diet.DietSuggestionHelper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class SmartSwapServiceImpl implements SmartSwapService {

    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final UserAllergyRepository allergyRepository;

    private final UserInjuryRepository userInjuryRepository;
    private final DietSuggestionHelper dietSuggestionHelper;

    private static final Map<String, List<String>> CATEGORY_SWAP_MAP = Map.of(
            "FRUIT", List.of("FRUIT", "BEVERAGE", "DAIRY"),
            "BEVERAGE", List.of("BEVERAGE", "FRUIT", "DAIRY"),
            "DAIRY", List.of("DAIRY", "FRUIT", "BEVERAGE"),
            "VEGETABLE", List.of("VEGETABLE", "VEG"),
            "VEG", List.of("VEGETABLE", "VEG"),
            "MEAT", List.of("MEAT", "SEAFOOD"),
            "SEAFOOD", List.of("SEAFOOD", "MEAT"),
            "NOODLE_SOUP", List.of("NOODLE_SOUP", "DRY_DISH", "GRAIN"),
            "GRAIN", List.of("GRAIN", "DRY_DISH", "NOODLE_SOUP"),
            "DRY_DISH", List.of("DRY_DISH", "GRAIN", "NOODLE_SOUP"));

    @Override
    public List<FoodSmartSwapCandidateDTO> getFoodSwapCandidates(User user, FoodSmartSwapRequest request) {
        Food targetFood = foodRepository.findById(request.getFoodId())
                .orElseThrow(() -> new ResourceNotFoundException("Food not found with id: " + request.getFoodId()));

        BigDecimal servingQty = request.getCurrentServingQuantity() != null ? request.getCurrentServingQuantity()
                : new BigDecimal("100.0");
        BigDecimal factor = servingQty.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        BigDecimal targetCal = targetFood.getCaloriesPer100g().multiply(factor);
        BigDecimal targetProtein = targetFood.getProteinPer100g().multiply(factor);

        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(user.getId());
        Set<UUID> allergicFoodIds = allergies.stream()
                .filter(a -> a.getAllergyMaster() != null)
                .map(a -> a.getAllergyMaster().getId())
                .collect(Collectors.toSet());

        // Lấy tất cả thực phẩm để tìm các món thay thế cùng nhóm phù hợp nhất
        List<Food> candidatePool = foodRepository.findAllWithRelations();

        String targetCategoryCode = resolveCategoryCode(targetFood);
        List<String> allowedTargetCategories = CATEGORY_SWAP_MAP.getOrDefault(targetCategoryCode,
                List.of(targetCategoryCode));

        // Lọc món ăn: khác món hiện tại, không dị ứng, BẮT BUỘC thuộc kiểu DISH / BOTH
        // (bỏ INGREDIENT), calo > 0, và thuộc nhóm tương đương
        List<Food> filteredFoods = candidatePool.stream()
                .filter(food -> !food.getId().equals(targetFood.getId()))
                .filter(food -> !allergicFoodIds.contains(food.getId()))
                .filter(food -> food.getType() == FoodType.DISH || food.getType() == FoodType.BOTH)
                .filter(food -> food.getCaloriesPer100g() != null
                        && food.getCaloriesPer100g().compareTo(BigDecimal.ZERO) > 0)
                .filter(food -> {
                    String candCatCode = resolveCategoryCode(food);
                    return allowedTargetCategories.contains(candCatCode);
                })
                .collect(Collectors.toList());

        // Nếu quá ít món thuộc cùng nhóm, nới lỏng theo đặc tính protein / carbs nhưng
        // vẫn BẮT BUỘC là DISH / BOTH
        if (filteredFoods.size() < 3) {
            boolean isHighProtein = targetFood.getProteinPer100g() != null
                    && targetFood.getProteinPer100g().doubleValue() >= 8.0;
            filteredFoods = candidatePool.stream()
                    .filter(food -> !food.getId().equals(targetFood.getId()))
                    .filter(food -> !allergicFoodIds.contains(food.getId()))
                    .filter(food -> food.getType() == FoodType.DISH || food.getType() == FoodType.BOTH)
                    .filter(food -> food.getCaloriesPer100g() != null
                            && food.getCaloriesPer100g().compareTo(BigDecimal.ZERO) > 0)
                    .filter(food -> {
                        if (isHighProtein) {
                            return food.getProteinPer100g() != null && food.getProteinPer100g().doubleValue() >= 6.0;
                        }
                        return true;
                    })
                    .collect(Collectors.toList());
        }

        List<FoodSmartSwapCandidateDTO> candidates = new ArrayList<>();

        for (Food food : filteredFoods) {
            BigDecimal recFactor = targetCal.divide(food.getCaloriesPer100g(), 4, RoundingMode.HALF_UP);
            BigDecimal recQuantity = recFactor.multiply(new BigDecimal("100")).setScale(1, RoundingMode.HALF_UP);

            BigDecimal minQty = dietSuggestionHelper.getMinQuantityForCategory(food);
            BigDecimal maxQty = dietSuggestionHelper.getMaxQuantityForCategory(food);

            if (recQuantity.compareTo(minQty) < 0) {
                recQuantity = minQty;
            } else if (recQuantity.compareTo(maxQty) > 0) {
                recQuantity = maxQty;
            }

            BigDecimal actualFactor = recQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
            BigDecimal candCal = food.getCaloriesPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candProtein = food.getProteinPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candFat = food.getFatPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candCarbs = food.getCarbsPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);

            // Tính điểm tương đồng Macro
            double score = 85.0;
            if (targetCal.compareTo(BigDecimal.ZERO) > 0 && targetProtein.compareTo(BigDecimal.ZERO) > 0) {
                double targetRatio = targetProtein.doubleValue() / Math.max(1.0, targetCal.doubleValue());
                double candRatio = candProtein.doubleValue() / Math.max(1.0, candCal.doubleValue());
                double diff = Math.abs(targetRatio - candRatio);
                score = Math.max(65.0, Math.min(98.0, 100.0 - (diff * 200.0)));
            }

            if (targetFood.getCategory() != null && food.getCategory() != null &&
                    targetFood.getCategory().getId().equals(food.getCategory().getId())) {
                score = Math.min(99.0, score + 5.0);
            }

            String candCatCode = resolveCategoryCode(food);

            double roundedScore = Math.round(score * 10.0) / 10.0;
            String categoryName = food.getCategory() != null ? food.getCategory().getName() : "Khác";

            String matchLabel;
            if (roundedScore >= 85.0) {
                matchLabel = "Khuyên dùng";
            } else if (roundedScore >= 70.0) {
                matchLabel = "Ổn";
            } else {
                matchLabel = "Không khuyên dùng";
            }

            candidates.add(FoodSmartSwapCandidateDTO.builder()
                    .foodId(food.getId())
                    .foodName(food.getName())
                    .categoryName(categoryName)
                    .imageUrl(food.getImageUrl())
                    .recommendedServingQuantity(recQuantity)
                    .calories(candCal)
                    .protein(candProtein)
                    .fat(candFat)
                    .carbs(candCarbs)
                    .matchScore(roundedScore)
                    .matchReason(matchLabel)
                    .swapGroup(candCatCode)
                    .build());
        }

        return candidates.stream()
                .sorted(Comparator.comparing(FoodSmartSwapCandidateDTO::getMatchScore).reversed())
                .limit(15)
                .collect(Collectors.toList());
    }

    @Override
    public List<ExerciseSmartSwapCandidateDTO> getExerciseSwapCandidates(User user, ExerciseSmartSwapRequest request) {
        Exercise targetEx = exerciseRepository.findById(request.getExerciseId())
                .orElseThrow(
                        () -> new ResourceNotFoundException("Exercise not found with id: " + request.getExerciseId()));

        List<UserInjury> userInjuries = userInjuryRepository.findAllByUserId(user.getId());
        Set<UUID> restrictedBodyPartIds = new HashSet<>();
        for (UserInjury ui : userInjuries) {
            Injury injury = ui.getInjury();
            if (injury != null && injury.getBodyPart() != null) {
                restrictedBodyPartIds.add(injury.getBodyPart().getId());
            }
        }

        List<Exercise> allExercises = exerciseRepository.findAll();
        List<ExerciseSmartSwapCandidateDTO> candidates = new ArrayList<>();

        for (Exercise ex : allExercises) {
            if (ex.getId().equals(targetEx.getId())) {
                continue;
            }
            if (ex.getBodyPart() != null && restrictedBodyPartIds.contains(ex.getBodyPart().getId())) {
                continue;
            }

            double score = 70.0;
            String targetMuscleName = ex.getTargetMuscle() != null ? ex.getTargetMuscle().getName() : "Không xác định";
            String bodyPartName = ex.getBodyPart() != null ? ex.getBodyPart().getName() : "Không xác định";

            if (targetEx.getTargetMuscle() != null && ex.getTargetMuscle() != null &&
                    targetEx.getTargetMuscle().getId().equals(ex.getTargetMuscle().getId())) {
                score += 20.0;
            } else if (targetEx.getBodyPart() != null && ex.getBodyPart() != null &&
                    targetEx.getBodyPart().getId().equals(ex.getBodyPart().getId())) {
                score += 10.0;
            }

            if (targetEx.getDifficulty() != null && targetEx.getDifficulty().equals(ex.getDifficulty())) {
                score += 5.0;
            }

            double roundedScore = Math.min(99.0, Math.round(score * 10.0) / 10.0);
            String difficultyStr = ex.getDifficulty() != null ? ex.getDifficulty().name() : "BEGINNER";

            candidates.add(ExerciseSmartSwapCandidateDTO.builder()
                    .exerciseId(ex.getId())
                    .name(ex.getName())
                    .bodyPartName(bodyPartName)
                    .targetMuscleName(targetMuscleName)
                    .difficulty(difficultyStr)
                    .metValue(ex.getMetValue())
                    .mediaUrl(ex.getMediaUrl())
                    .matchScore(roundedScore)
                    .matchReason(String.format("Cùng nhóm cơ %s, an toàn với chấn thương", targetMuscleName))
                    .build());
        }

        return candidates.stream()
                .sorted(Comparator.comparing(ExerciseSmartSwapCandidateDTO::getMatchScore).reversed())
                .limit(10)
                .collect(Collectors.toList());
    }

    private String resolveCategoryCode(Food food) {
        if (food == null || food.getCategory() == null || food.getCategory().getCode() == null) {
            return "OTHERS";
        }
        String code = food.getCategory().getCode().toUpperCase().trim();
        if ("VEG".equals(code)) {
            return "VEGETABLE";
        }
        return code;
    }
}
