package com.bodypilot.backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.springframework.stereotype.Service;

import com.bodypilot.backend.model.dto.nutrition.CalorieCalculationResult;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.model.enums.Goal;

@Service
public class CalorieCalculatorService {

    /**
     * Calculates BMI, BMR, TDEE, and Target Calories based on user metrics.
     *
     * @param weight        Weight in kilograms (must be strictly positive)
     * @param height        Height in centimeters (must be strictly positive)
     * @param age           Age in years (must ưbe strictly positive)
     * @param gender        Gender enum (MALE or FEMALE)
     * @param activityLevel Activity level multiplier category
     * @param goal          Fitness goal for target calorie adjustment
     * @return CalorieCalculationResult containing BMI (1 decimal), BMR, TDEE, and
     *         Target Calories (rounded)
     */
    public CalorieCalculationResult calculateMetrics(double weight, double height, int age, Gender gender,
            ActivityLevel activityLevel, Goal goal) {
        // Validate input mathematically
        if (weight <= 0 || height <= 0 || age <= 0) {
            throw new IllegalArgumentException("Weight, height, and age must be strictly positive values.");
        }

        // Validate required enums
        if (gender == null || activityLevel == null || goal == null) {
            throw new IllegalArgumentException("Gender, ActivityLevel, and Goal parameters cannot be null.");
        }

        // 1. Calculate BMI: weight (kg) / (height (m) ^ 2)
        double heightInMeters = height / 100.0;
        double bmiRaw = weight / Math.pow(heightInMeters, 2);
        double bmi = round(bmiRaw, 1);

        // 2. Calculate BMR using Mifflin-St Jeor Equation
        // Base formula: 10 * weight + 6.25 * height - 5 * age
        double bmrBase = 10 * weight + 6.25 * height - 5 * age;
        double bmrRaw = (gender == Gender.MALE) ? (bmrBase + 5) : (bmrBase - 161);
        double bmr = Math.round(bmrRaw);

        // 3. Calculate TDEE (BMR * Activity Level Multiplier)
        double tdeeRaw = bmr * activityLevel.getMultiplier();
        double tdee = Math.round(tdeeRaw);

        // 4. Calculate Target Calories based on Goal
        double targetCaloriesRaw = calculateTargetCalories(tdee, goal);
        double targetCalories = Math.round(targetCaloriesRaw);

        // 5. Calculate Target Macros based on Goal (Matching Mobile FE formulas)
        MacroRatio macros = getMacroRatio(goal);
        double targetProtein = Math.round((targetCalories * macros.proteinRatio) / 4.0);
        double targetFat = Math.round((targetCalories * macros.fatRatio) / 9.0);
        double targetCarbs = Math.round((targetCalories * macros.carbsRatio) / 4.0);

        return CalorieCalculationResult.builder()
                .bmi(bmi)
                .bmr(bmr)
                .tdee(tdee)
                .targetCalories(targetCalories)
                .targetProtein(targetProtein)
                .targetFat(targetFat)
                .targetCarbs(targetCarbs)
                .build();
    }

    public record MacroRatio(double proteinRatio, double fatRatio, double carbsRatio) {}

    /**
     * Gets the macro distribution ratio based on user fitness goal.
     * Matches the mobile frontend _goalMacros definitions:
     * - MAINTAIN: 25% Protein, 25% Fat, 50% Carbs
     * - LOSE_0_5KG: 35% Protein, 25% Fat, 40% Carbs
     * - LOSE_1KG: 40% Protein, 20% Fat, 40% Carbs
     * - GAIN_0_5KG: 25% Protein, 20% Fat, 55% Carbs
     * - GAIN_1KG: 20% Protein, 25% Fat, 55% Carbs
     * - GAIN_MUSCLE: 40% Protein, 20% Fat, 40% Carbs
     * - HEALTHY_LIFESTYLE: 25% Protein, 30% Fat, 45% Carbs
     */
    public MacroRatio getMacroRatio(Goal goal) {
        if (goal == null) {
            return new MacroRatio(0.25, 0.25, 0.50);
        }
        return switch (goal) {
            case MAINTAIN -> new MacroRatio(0.25, 0.25, 0.50);
            case LOSE_0_5KG -> new MacroRatio(0.35, 0.25, 0.40);
            case LOSE_1KG -> new MacroRatio(0.40, 0.20, 0.40);
            case GAIN_0_5KG -> new MacroRatio(0.25, 0.20, 0.55);
            case GAIN_1KG -> new MacroRatio(0.20, 0.25, 0.55);
            case GAIN_MUSCLE -> new MacroRatio(0.40, 0.20, 0.40);
            case HEALTHY_LIFESTYLE, ENDURANCE -> new MacroRatio(0.25, 0.30, 0.45);
        };
    }

    /**
     * Adjusts the TDEE based on the specific health and fitness goal.
     */
    private double calculateTargetCalories(double tdee, Goal goal) {
        return switch (goal) {
            case MAINTAIN, HEALTHY_LIFESTYLE, ENDURANCE -> tdee;
            case LOSE_0_5KG -> tdee - 500;
            case LOSE_1KG -> tdee - 1000;
            case GAIN_0_5KG -> tdee + 500;
            case GAIN_1KG -> tdee + 1000;
            case GAIN_MUSCLE -> tdee + 300; // Moderate surplus for lean mass gain
            default -> throw new IllegalArgumentException("Unexpected value: " + goal);
        };
    }

    /**
     * Calculates the calories burned during an exercise based on MET value,
     * duration, and user's weight.
     * Formula: Calories = (MET * 3.5 * Weight (kg) / 200.0) * Duration in minutes
     *
     * @param metValue        The Metabolic Equivalent of Task (MET) value for the
     *                        exercise.
     * @param durationMinutes The duration of the exercise in minutes.
     * @param weightKg        The weight of the user in kilograms.
     * @return The estimated calories burned (rounded to 1 decimal place).
     */
    public double calculateWorkoutCalories(Double metValue, Number durationMinutes, Double weightKg) {
        if (metValue == null || durationMinutes == null || weightKg == null) {
            return 0.0;
        }
        double duration = durationMinutes.doubleValue();
        if (metValue <= 0 || duration <= 0 || weightKg <= 0) {
            return 0.0;
        }

        double caloriesRaw = (metValue * 3.5 * weightKg / 200.0) * duration;
        return round(caloriesRaw, 1);
    }

    /**
     * Helper method to accurately round a double to specified decimal places.
     */
    private double round(double value, int places) {
        if (places < 0)
            throw new IllegalArgumentException("Decimal places cannot be negative.");

        BigDecimal bd = BigDecimal.valueOf(value);
        bd = bd.setScale(places, RoundingMode.HALF_UP);
        return bd.doubleValue();
    }
}
