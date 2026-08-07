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
    @DisplayName("TC12: Sinh thực đơn khi AI Key chưa sẵn sàng - Trả về Fallback JSON thông báo")
    void generateMealSuggestion_AiKeyMissing_ReturnsFallbackJson() throws Exception {
        // Arrange
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(llmRouterService.isAiReady()).thenReturn(false);
        String expectedFallback = "{\"error\": \"AI Key Chưa Sẵn Sàng\"}";
        when(dietSuggestionHelper.getFallbackJson(eq(startDate), anyString(), eq(7))).thenReturn(expectedFallback);

        // Act
        String result = geminiService.generateMealSuggestion(userId, startDate, 7, null);

        // Assert
        assertNotNull(result);
        assertEquals(expectedFallback, result);
        verify(llmRouterService, times(1)).isAiReady();
        verify(dietSuggestionHelper, times(1)).getFallbackJson(eq(startDate), anyString(), eq(7));
    }

    @Test
    @DisplayName("TC13: Sinh thực đơn khi không tìm thấy người dùng - Trả về Fallback JSON xử lý ngoại lệ")
    void generateMealSuggestion_UserNotFound_ReturnsFallbackJson() {
        // Arrange
        when(userRepository.findById(userId)).thenReturn(Optional.empty());
        String expectedFallback = "{\"error\": \"User not found\"}";
        when(dietSuggestionHelper.getFallbackJson(eq(startDate), anyString(), eq(7))).thenReturn(expectedFallback);

        // Act
        String result = geminiService.generateMealSuggestion(userId, startDate, 7, null);

        // Assert
        assertNotNull(result);
        assertEquals(expectedFallback, result);
        verify(userRepository, times(1)).findById(userId);
    }
}
