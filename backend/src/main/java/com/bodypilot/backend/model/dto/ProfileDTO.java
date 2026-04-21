package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileDTO {
    private String fullName;
    private String gender;
    private Integer age;
    private Double heightCm;
    private Boolean hasExperience;
    private String avatarUrl;
}
