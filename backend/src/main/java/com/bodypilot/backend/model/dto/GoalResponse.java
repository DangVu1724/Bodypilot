package com.bodypilot.backend.model.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class GoalResponse {
    private String type;
    private Double targetWeight;
    private LocalDate deadline;
    private String status;
}
