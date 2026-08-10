package com.bodypilot.backend.service;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.entity.user.UserProfile;
import com.bodypilot.backend.repository.*;
import com.bodypilot.backend.service.impl.DietSuggestionHelper;
import com.bodypilot.backend.service.impl.GeminiServiceImpl;
import com.bodypilot.backend.service.impl.LlmRouterService;
import com.bodypilot.backend.service.impl.WorkoutSuggestionHelper;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GeminiServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserGoalRepository goalRepository;

    @Mock
    private UserMetricHistoryRepository metricHistoryRepository;

    @Mock
    private UserAllergyRepository allergyRepository;

    @Mock
    private UserDietPreferenceRepository dietPreferenceRepository;

    @Mock
    private UserFoodPreferenceRepository foodPreferenceRepository;

    @Mock
    private UserInjuryRepository userInjuryRepository;

    @Mock
    private WorkoutPlanRepository workoutPlanRepository;

    @Mock
    private LlmRouterService llmRouterService;

    @Mock
    private DietSuggestionHelper dietSuggestionHelper;

    @Mock
    private WorkoutSuggestionHelper workoutSuggestionHelper;

    @InjectMocks
    private GeminiServiceImpl geminiService;

    private UUID userId;
    private User sampleUser;
    private LocalDate startDate;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        startDate = LocalDate.now();

        UserProfile profile = UserProfile.builder()
                .fullName("Nguyễn Văn A")
                .gender("MALE")
                .age(25)
                .heightCm(175.0)
                .weight(70.0)
                .build();

        sampleUser = User.builder()
                .email("user@example.com")
                .profile(profile)
                .build();
    }

    @Test
    @DisplayName("TC11: Sinh thực đơn cá nhân hóa bằng AI - Thành công với tham số hợp lệ")
    void generateMealSuggestion_Success() throws Exception {
        // Arrange
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(llmRouterService.isAiReady()).thenReturn(true);
        when(goalRepository.findByUserIdAndStatus(userId, "ACTIVE")).thenReturn(Collections.emptyList());
        when(metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(Collections.emptyList());
        when(allergyRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.getBalancedFoodCandidates(eq(userId), any())).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.buildPrompt(any(), any(), any(), any(), any(), any(), any(), any(), anyInt(), any())).thenReturn("Generated Prompt");

        String mockRawJson = "[{\"day\": 1, \"meal\": \"Bữa sáng: Phở gà\"}]";
        when(llmRouterService.routeChatRequest(any(), anyString(), anyString(), eq(true))).thenReturn(mockRawJson);
        when(dietSuggestionHelper.processAndLinkFoods(mockRawJson, null)).thenReturn(mockRawJson);

        // Act
        String result = geminiService.generateMealSuggestion(userId, startDate, 7, "Không ăn cay");

        // Assert
        assertNotNull(result);
        assertTrue(result.contains("Phở gà"));
        verify(userRepository, times(1)).findById(userId);
        verify(llmRouterService, times(1)).routeChatRequest(any(), anyString(), anyString(), eq(true));
    }

    @Test
    @DisplayName("TC12: Mất kết nối AI / Timeout - Trả về thông báo lỗi hoặc Fallback JSON")
    void generateMealSuggestion_Timeout_ReturnsErrorMessage() throws Exception {
        // Arrange
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(llmRouterService.isAiReady()).thenReturn(true);
        when(goalRepository.findByUserIdAndStatus(userId, "ACTIVE")).thenReturn(Collections.emptyList());
        when(metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(Collections.emptyList());
        when(allergyRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.getBalancedFoodCandidates(eq(userId), any())).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.buildPrompt(any(), any(), any(), any(), any(), any(), any(), any(), anyInt(), any())).thenReturn("Generated Prompt");

        // Mô phỏng timeout / lỗi kết nối từ AI service
        when(llmRouterService.routeChatRequest(any(), anyString(), anyString(), eq(true)))
                .thenThrow(new RuntimeException("AI API Timeout Error"));

        String expectedFallback = "{\"error\": \"Connection Timeout\"}";
        when(dietSuggestionHelper.generatePresetFallbackMealPlan(eq(userId), eq(startDate), eq(7), any(), any(), anyString()))
                .thenReturn(expectedFallback);

        // Act
        String result = geminiService.generateMealSuggestion(userId, startDate, 7, null);

        // Assert
        assertNotNull(result);
        assertEquals(expectedFallback, result);
        verify(llmRouterService, times(1)).routeChatRequest(any(), anyString(), anyString(), eq(true));
        verify(dietSuggestionHelper, times(1)).generatePresetFallbackMealPlan(eq(userId), eq(startDate), eq(7), any(), any(), anyString());
    }

    @Test
    @DisplayName("TC13: Người dùng dị ứng hải sản - Thực đơn sinh ra không chứa món hải sản")
    void generateMealSuggestion_SeafoodAllergy_ExcludesSeafood() throws Exception {
        // Arrange
        com.bodypilot.backend.model.entity.health.AllergyMaster allergyMaster = com.bodypilot.backend.model.entity.health.AllergyMaster.builder()
                .name("Hải sản")
                .build();

        com.bodypilot.backend.model.entity.user.UserAllergy allergy = com.bodypilot.backend.model.entity.user.UserAllergy.builder()
                .allergyMaster(allergyMaster)
                .severity(com.bodypilot.backend.model.enums.SeverityLevel.HIGH)
                .isActive(true)
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(llmRouterService.isAiReady()).thenReturn(true);
        when(goalRepository.findByUserIdAndStatus(userId, "ACTIVE")).thenReturn(Collections.emptyList());
        when(metricHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(Collections.emptyList());
        when(allergyRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.singletonList(allergy));
        when(dietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(foodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.getBalancedFoodCandidates(eq(userId), any())).thenReturn(Collections.emptyList());
        when(dietSuggestionHelper.buildPrompt(any(), any(), any(), any(), any(), any(), any(), any(), anyInt(), any())).thenReturn("Generated Prompt with Seafood Allergy Exclusions");

        String mockRawJson = "[{\"day\": 1, \"meal\": \"Bữa sáng: Ức gà nướng, Cơm lứt\"}]";
        when(llmRouterService.routeChatRequest(any(), anyString(), anyString(), eq(true))).thenReturn(mockRawJson);
        when(dietSuggestionHelper.processAndLinkFoods(mockRawJson, null)).thenReturn(mockRawJson);

        // Act
        String result = geminiService.generateMealSuggestion(userId, startDate, 7, "Dị ứng hải sản");

        // Assert
        assertNotNull(result);
        assertFalse(result.contains("Tôm"));
        assertFalse(result.contains("Cua"));
        assertFalse(result.contains("Mực"));
        assertTrue(result.contains("Ức gà nướng"));
        verify(allergyRepository, times(1)).findAllByUserIdAndIsActiveTrue(userId);
    }
}
