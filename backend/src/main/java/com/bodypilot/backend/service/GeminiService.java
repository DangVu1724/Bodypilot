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
    String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days, String userFeedback);
    String generateMealSuggestion(UUID userId, LocalDate startDate, Integer days);

    /**
     * Generates a personalized weekly workout plan suggestion using Gemini
     * based on user profile metrics, active goals, and injuries.
     *
     * @param userId UUID of the user.
     * @param startDate LocalDate of the starting date of the plan.
     * @param days Integer number of days for the workout plan.
     * @return JSON-formatted response containing the weekly workout suggestion.
     */
    String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days, String focusBodyPart);
    String generateWorkoutSuggestion(UUID userId, LocalDate startDate, Integer days);
}

