package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapRequest;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapRequest;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.model.entity.workout.Exercise;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.SmartSwapService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SmartSwapServiceImpl implements SmartSwapService {

    private final FoodRepository foodRepository;
    private final ExerciseRepository exerciseRepository;
    private final UserAllergyRepository allergyRepository;
    private final UserDietPreferenceRepository dietPreferenceRepository;
    private final UserFoodPreferenceRepository foodPreferenceRepository;
    private final UserInjuryRepository userInjuryRepository;

    @Override
    public List<FoodSmartSwapCandidateDTO> getFoodSwapCandidates(User user, FoodSmartSwapRequest request) {
        Food targetFood = foodRepository.findById(request.getFoodId())
                .orElseThrow(() -> new ResourceNotFoundException("Food not found with id: " + request.getFoodId()));

        BigDecimal servingQty = request.getCurrentServingQuantity() != null ? request.getCurrentServingQuantity() : new BigDecimal("100.0");
        BigDecimal factor = servingQty.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        BigDecimal targetCal = targetFood.getCaloriesPer100g().multiply(factor);
        BigDecimal targetProtein = targetFood.getProteinPer100g().multiply(factor);

        List<UserAllergy> allergies = allergyRepository.findAllByUserIdAndIsActiveTrue(user.getId());
        Set<UUID> allergicFoodIds = allergies.stream()
                .filter(a -> a.getAllergyMaster() != null)
                .map(a -> a.getAllergyMaster().getId())
                .collect(Collectors.toSet());

        List<Food> allFoods = foodRepository.findAll();
        List<FoodSmartSwapCandidateDTO> candidates = new ArrayList<>();

        for (Food food : allFoods) {
            if (food.getId().equals(targetFood.getId())) {
                continue;
            }
            if (food.getCaloriesPer100g() == null || food.getCaloriesPer100g().compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            // Calculate recommended serving quantity to match target calories
            BigDecimal recFactor = targetCal.divide(food.getCaloriesPer100g(), 4, RoundingMode.HALF_UP);
            BigDecimal recQuantity = recFactor.multiply(new BigDecimal("100")).setScale(1, RoundingMode.HALF_UP);

            if (recQuantity.compareTo(new BigDecimal("30.0")) < 0) {
                recQuantity = new BigDecimal("30.0");
            } else if (recQuantity.compareTo(new BigDecimal("500.0")) > 0) {
                recQuantity = new BigDecimal("500.0");
            }

            BigDecimal actualFactor = recQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
            BigDecimal candCal = food.getCaloriesPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candProtein = food.getProteinPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candFat = food.getFatPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);
            BigDecimal candCarbs = food.getCarbsPer100g().multiply(actualFactor).setScale(1, RoundingMode.HALF_UP);

            // Compute macro match score (comparing protein similarity)
            double score = 85.0;
            if (targetCal.compareTo(BigDecimal.ZERO) > 0 && targetProtein.compareTo(BigDecimal.ZERO) > 0) {
                double targetRatio = targetProtein.doubleValue() / Math.max(1.0, targetCal.doubleValue());
                double candRatio = candProtein.doubleValue() / Math.max(1.0, candCal.doubleValue());
                double diff = Math.abs(targetRatio - candRatio);
                score = Math.max(65.0, Math.min(98.0, 100.0 - (diff * 200.0)));
            }

            // Boost score if same category
            if (targetFood.getCategory() != null && food.getCategory() != null &&
                    targetFood.getCategory().getId().equals(food.getCategory().getId())) {
                score = Math.min(99.0, score + 5.0);
            }

            double roundedScore = Math.round(score * 10.0) / 10.0;
            String categoryName = food.getCategory() != null ? food.getCategory().getName() : "Khác";

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
                    .matchReason(String.format("Tương đồng %.0f%% Dinh dưỡng & Calo", roundedScore))
                    .build());
        }

        return candidates.stream()
                .sorted(Comparator.comparing(FoodSmartSwapCandidateDTO::getMatchScore).reversed())
                .limit(10)
                .collect(Collectors.toList());
    }

    @Override
    public List<ExerciseSmartSwapCandidateDTO> getExerciseSwapCandidates(User user, ExerciseSmartSwapRequest request) {
        Exercise targetEx = exerciseRepository.findById(request.getExerciseId())
                .orElseThrow(() -> new ResourceNotFoundException("Exercise not found with id: " + request.getExerciseId()));

        List<UserInjury> userInjuries = userInjuryRepository.findAllByUserId(user.getId());
        Set<String> restrictedCodes = new HashSet<>();
        for (UserInjury ui : userInjuries) {
            Injury injury = ui.getInjury();
            if (injury != null && injury.getRestrictedExercises() != null) {
                restrictedCodes.addAll(injury.getRestrictedExercises());
            }
        }

        List<Exercise> allExercises = exerciseRepository.findAll();
        List<ExerciseSmartSwapCandidateDTO> candidates = new ArrayList<>();

        for (Exercise ex : allExercises) {
            if (ex.getId().equals(targetEx.getId())) {
                continue;
            }
            if (ex.getCode() != null && restrictedCodes.contains(ex.getCode())) {
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
}
