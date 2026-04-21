package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.CalorieCalculationResult;
import com.bodypilot.backend.model.enums.ActivityLevel;
import com.bodypilot.backend.model.enums.Gender;
import com.bodypilot.backend.model.enums.Goal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CalorieCalculatorServiceTest {

    private CalorieCalculatorService service;

    @BeforeEach
    void setUp() {
        service = new CalorieCalculatorService();
    }

    @Test
    void calculateMetrics_Male_Moderate_Maintain() {
        double weight = 70.0;
        double height = 175.0;
        int age = 25;
        
        CalorieCalculationResult result = service.calculateMetrics(
            weight, height, age, Gender.MALE, ActivityLevel.MODERATE, Goal.MAINTAIN
        );
        
        // BMI = 70 / (1.75^2) = 22.857 -> 22.9
        assertEquals(22.9, result.getBmi());
        
        // BMR = 10*70 + 6.25*175 - 5*25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75 -> 1674.0
        assertEquals(1674.0, result.getBmr());
        
        // TDEE = 1674 * 1.55 = 2594.7 -> 2595.0
        assertEquals(2595.0, result.getTdee());
        
        // Target = TDEE = 2595.0
        assertEquals(2595.0, result.getTargetCalories());
    }

    @Test
    void calculateMetrics_Female_Sedentary_Lose05() {
        double weight = 60.0;
        double height = 160.0;
        int age = 30;
        
        CalorieCalculationResult result = service.calculateMetrics(
            weight, height, age, Gender.FEMALE, ActivityLevel.SEDENTARY, Goal.LOSE_0_5KG
        );
        
        // BMI = 60 / (1.60^2) = 23.4375 -> 23.4
        assertEquals(23.4, result.getBmi());
        
        // BMR = 10*60 + 6.25*160 - 5*30 - 161 = 600 + 1000 - 150 - 161 = 1289.0
        assertEquals(1289.0, result.getBmr());
        
        // TDEE = 1289 * 1.2 = 1546.8 -> 1547.0
        assertEquals(1547.0, result.getTdee());
        
        // Target = 1547 - 500 = 1047.0
        assertEquals(1047.0, result.getTargetCalories());
    }

    @Test
    void calculateMetrics_Male_GainMuscle_Active() {
        double weight = 65.0;
        double height = 180.0;
        int age = 22;
        
        CalorieCalculationResult result = service.calculateMetrics(
            weight, height, age, Gender.MALE, ActivityLevel.ACTIVE, Goal.GAIN_MUSCLE
        );
        
        // BMI = 65 / (1.80^2) = 20.06 -> 20.1
        assertEquals(20.1, result.getBmi());
        
        // BMR = 10*65 + 6.25*180 - 5*22 + 5 = 650 + 1125 - 110 + 5 = 1670.0
        assertEquals(1670.0, result.getBmr());
        
        // TDEE = 1670 * 1.725 = 2880.75 -> 2881.0
        assertEquals(2881.0, result.getTdee());
        
        // Target = 2881 + 300 = 3181.0
        assertEquals(3181.0, result.getTargetCalories());
    }

    @Test
    void calculateMetrics_InvalidInput_NegativeWeight_ThrowsException() {
        Exception exception = assertThrows(IllegalArgumentException.class, () -> {
            service.calculateMetrics(-10, 170, 25, Gender.MALE, ActivityLevel.ACTIVE, Goal.MAINTAIN);
        });
        
        assertTrue(exception.getMessage().contains("strictly positive"));
    }

    @Test
    void calculateMetrics_InvalidInput_NullEnum_ThrowsException() {
        Exception exception = assertThrows(IllegalArgumentException.class, () -> {
            service.calculateMetrics(70, 170, 25, null, ActivityLevel.ACTIVE, Goal.MAINTAIN);
        });
        
        assertTrue(exception.getMessage().contains("cannot be null"));
    }
}
