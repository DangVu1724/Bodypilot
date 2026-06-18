package com.bodypilot.backend.service;

import java.time.LocalDate;
import java.util.UUID;

public interface GeminiService {
    /**
     * Generates a personalized weekly diet/meal plan suggestion using Gemini
     * based on user profile metrics, active goals, allergies, and dietary preferences.
     *
     * @param userId UUID of the user.
     * @param startDate LocalDate of the starting date of the plan.
     * @return JSON-formatted response containing the weekly diet suggestion.
     */
    String generateMealSuggestion(UUID userId, LocalDate startDate);
}
