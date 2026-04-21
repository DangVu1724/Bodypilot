package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssessmentSubmissionRequest {
    private String selectedGoal;
    private String selectedGender;
    private Integer age;
    private Double heightCm;
    private Double weight;
    private Double targetWeight;
    private List<String> selectedConditions;
    private List<String> selectedInjuries;
    private Boolean hasExperience;
    private String activityLevel;
}
