package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.entity.nutrition.DailyEating;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.nutrition.MealItem;
import com.bodypilot.backend.model.entity.nutrition.MealSlot;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.repository.DailyEatingRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.MealItemRepository;
import com.bodypilot.backend.repository.MealSlotRepository;
import com.bodypilot.backend.service.impl.NutritionDiaryServiceImpl;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NutritionDiaryServiceTest {

    @Mock
    private DailyEatingRepository dailyEatingRepository;

    @Mock
    private MealSlotRepository mealSlotRepository;

    @Mock
    private MealItemRepository mealItemRepository;

    @Mock
    private FoodRepository foodRepository;

    @InjectMocks
    private NutritionDiaryServiceImpl nutritionDiaryService;

    private User sampleUser;
    private Food sampleFood;
    private UUID foodId;
    private LocalDate today;

    @BeforeEach
    void setUp() {
        foodId = UUID.randomUUID();
        today = LocalDate.now();

        sampleUser = User.builder()
                .email("test@example.com")
                .build();

        sampleFood = Food.builder()
                .name("Ức gà luộc")
                .caloriesPer100g(BigDecimal.valueOf(165))
                .proteinPer100g(BigDecimal.valueOf(31))
                .fatPer100g(BigDecimal.valueOf(3.6))
                .carbsPer100g(BigDecimal.ZERO)
                .build();
        sampleFood.setId(foodId);
    }

    @Test
    @DisplayName("TC08: Thêm món ăn (150g Ức gà) - Cập nhật nhật ký và tính toán tổng calo")
    void addFoodToDiary_ValidItem_Success() {
        // Arrange
        MealItemDTO itemDTO = MealItemDTO.builder()
                .foodId(foodId)
                .servingQuantity(BigDecimal.valueOf(150))
                .build();

        DailyEating dailyEating = DailyEating.builder()
                .user(sampleUser)
                .date(today)
                .totalCaloriesEaten(BigDecimal.ZERO)
                .mealSlots(new ArrayList<>())
                .build();

        MealSlot mealSlot = MealSlot.builder()
                .dailyEating(dailyEating)
                .mealType(MealType.BREAKFAST)
                .items(new ArrayList<>())
                .build();

        when(dailyEatingRepository.findByUserAndDate(sampleUser, today)).thenReturn(Optional.of(dailyEating));
        when(mealSlotRepository.findByDailyEatingAndMealType(dailyEating, MealType.BREAKFAST)).thenReturn(Optional.of(mealSlot));
        when(foodRepository.findById(foodId)).thenReturn(Optional.of(sampleFood));

        // Act
        DailyEatingDTO response = nutritionDiaryService.addFoodToDiary(sampleUser, today, MealType.BREAKFAST, itemDTO);

        // Assert
        assertNotNull(response);
        verify(mealItemRepository, times(1)).save(any(MealItem.class));
        verify(dailyEatingRepository, times(1)).save(dailyEating);
    }

    @Test
    @DisplayName("TC09: Khối lượng bằng 0 (0g) - Ném ngoại lệ IllegalArgumentException báo lỗi dữ liệu")
    void addFoodToDiary_ZeroQuantity_ThrowsException() {
        // Arrange
        MealItemDTO itemDTO = MealItemDTO.builder()
                .foodId(foodId)
                .servingQuantity(BigDecimal.ZERO)
                .build();

        // Act & Assert
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            nutritionDiaryService.addFoodToDiary(sampleUser, today, MealType.BREAKFAST, itemDTO);
        });

        assertTrue(exception.getMessage().contains("lớn hơn 0"));
        verifyNoInteractions(mealItemRepository);
    }

    @Test
    @DisplayName("TC10: Xóa món ăn khỏi nhật ký - Cập nhật tổng calo và xóa thành công")
    void removeFoodFromDiary_ExistingItem_DeletesAndRecalculates() {
        // Arrange
        UUID mealItemId = UUID.randomUUID();

        DailyEating dailyEating = DailyEating.builder()
                .user(sampleUser)
                .date(today)
                .totalCaloriesEaten(BigDecimal.valueOf(247.5))
                .mealSlots(new ArrayList<>())
                .build();

        MealSlot mealSlot = MealSlot.builder()
                .dailyEating(dailyEating)
                .mealType(MealType.LUNCH)
                .items(new ArrayList<>())
                .build();

        MealItem mealItem = new MealItem();
        mealItem.setId(mealItemId);
        mealItem.setMealSlot(mealSlot);
        mealItem.setCaloriesSnapshot(BigDecimal.valueOf(247.5));
        mealSlot.getItems().add(mealItem);

        when(mealItemRepository.findById(mealItemId)).thenReturn(Optional.of(mealItem));

        // Act
        nutritionDiaryService.removeFoodFromDiary(mealItemId);

        // Assert
        verify(mealItemRepository, times(1)).delete(mealItem);
        verify(dailyEatingRepository, times(1)).save(dailyEating);
        assertEquals(0, BigDecimal.ZERO.compareTo(dailyEating.getTotalCaloriesEaten()));
    }
}
