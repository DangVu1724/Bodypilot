package com.bodypilot.backend.model.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserMetricsResponse {
    private Double weight;
    private Double heightCm;
    private Integer age;
    private String goal;
    private String activityLevel;
    private Double bmi;
    private Double bmr;
    private Double tdee;
    private Double targetCalories;
}
