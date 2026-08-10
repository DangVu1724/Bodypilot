package com.bodypilot.backend.service;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.common.PageResponse;
import com.bodypilot.backend.model.dto.nutrition.FoodResponse;
import com.bodypilot.backend.model.dto.nutrition.FoodSummaryResponse;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.nutrition.FoodCategory;
import com.bodypilot.backend.model.enums.FoodType;
import com.bodypilot.backend.repository.DietTagRepository;
import com.bodypilot.backend.repository.FoodCategoryRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.service.impl.FoodServiceImpl;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FoodServiceTest {

    @Mock
    private FoodRepository foodRepository;

    @Mock
    private FoodCategoryRepository foodCategoryRepository;

    @Mock
    private DietTagRepository dietTagRepository;

    @InjectMocks
    private FoodServiceImpl foodService;

    private Food sampleFood;
    private FoodCategory sampleCategory;
    private UUID sampleId;

    @BeforeEach
    void setUp() {
        sampleId = UUID.randomUUID();

        sampleCategory = FoodCategory.builder()
                .name("Thịt & Gia cầm")
                .code("MEAT")
                .build();

        sampleFood = Food.builder()
                .name("Ức gà luộc")
                .type(FoodType.DISH)
                .caloriesPer100g(BigDecimal.valueOf(165))
                .proteinPer100g(BigDecimal.valueOf(31))
                .fatPer100g(BigDecimal.valueOf(3.6))
                .carbsPer100g(BigDecimal.ZERO)
                .category(sampleCategory)
                .healthScore(90)
                .build();
    }

    @Test
    @DisplayName("TC06: Tìm kiếm thực phẩm hợp lệ - 'Ức gà' trả về danh sách phù hợp")
    void searchFoods_ValidQuery_ReturnsPageResponse() {
        // Arrange
        String query = "Ức gà";
        Pageable pageable = PageRequest.of(0, 10);
        Page<Food> foodPage = new PageImpl<>(Collections.singletonList(sampleFood), pageable, 1);

        when(foodRepository.searchFoods(eq(query), any(), eq(pageable))).thenReturn(foodPage);

        // Act
        PageResponse<FoodSummaryResponse> response = foodService.searchFoods(query, null, pageable);

        // Assert
        assertNotNull(response);
        assertEquals(1, response.getContent().size());
        assertEquals("Ức gà luộc", response.getContent().get(0).getName());
        assertEquals(BigDecimal.valueOf(165), response.getContent().get(0).getCaloriesPer100g());
        verify(foodRepository, times(1)).searchFoods(eq(query), any(), eq(pageable));
    }

    @Test
    @DisplayName("TC07: Tìm kiếm từ khóa không tồn tại - 'xyz123' trả về danh sách rỗng")
    void searchFoods_NonExistingQuery_ReturnsEmptyPage() {
        // Arrange
        String query = "xyz123";
        Pageable pageable = PageRequest.of(0, 10);
        Page<Food> emptyPage = new PageImpl<>(Collections.emptyList(), pageable, 0);

        when(foodRepository.searchFoods(eq(query), any(), eq(pageable))).thenReturn(emptyPage);

        // Act
        PageResponse<FoodSummaryResponse> response = foodService.searchFoods(query, null, pageable);

        // Assert
        assertNotNull(response);
        assertTrue(response.getContent().isEmpty());
        assertEquals(0, response.getTotalElements());
        verify(foodRepository, times(1)).searchFoods(eq(query), any(), eq(pageable));
    }

    @Test
    @DisplayName("TC_FOOD_02: Lấy thông tin chi tiết món ăn theo ID - Thành công")
    void getFoodById_ExistingId_ReturnsFoodResponse() {
        // Arrange
        when(foodRepository.findById(sampleId)).thenReturn(Optional.of(sampleFood));

        // Act
        FoodResponse response = foodService.getFoodById(sampleId);

        // Assert
        assertNotNull(response);
        assertEquals("Ức gà luộc", response.getName());
        assertEquals(FoodType.DISH, response.getType());
        assertEquals(BigDecimal.valueOf(31), response.getProteinPer100g());
        verify(foodRepository, times(1)).findById(sampleId);
    }

    @Test
    @DisplayName("TC_FOOD_03: Lấy thông tin món ăn với ID không tồn tại - Thăng ngoại lệ ResourceNotFoundException")
    void getFoodById_NonExistingId_ThrowsResourceNotFoundException() {
        // Arrange
        UUID nonExistingId = UUID.randomUUID();
        when(foodRepository.findById(nonExistingId)).thenReturn(Optional.empty());

        // Act & Assert
        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            foodService.getFoodById(nonExistingId);
        });

        assertTrue(exception.getMessage().contains("Food not found with id"));
        verify(foodRepository, times(1)).findById(nonExistingId);
    }

    @Test
    @DisplayName("TC_FOOD_04: Xóa món ăn với ID hợp lệ - Thực thi thành công")
    void deleteFood_ExistingId_DeletesSuccessfully() {
        // Arrange
        when(foodRepository.existsById(sampleId)).thenReturn(true);
        doNothing().when(foodRepository).deleteById(sampleId);

        // Act
        assertDoesNotThrow(() -> foodService.deleteFood(sampleId));

        // Assert
        verify(foodRepository, times(1)).existsById(sampleId);
        verify(foodRepository, times(1)).deleteById(sampleId);
    }
}
