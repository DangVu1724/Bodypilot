package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.step.StepHistoryDTO;
import com.bodypilot.backend.model.dto.step.StepSyncRequest;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface StepService {
    StepHistoryDTO syncSteps(UUID userId, StepSyncRequest request);
    StepHistoryDTO getTodaySteps(UUID userId);
    List<StepHistoryDTO> getStepHistory(UUID userId, LocalDate startDate, LocalDate endDate);
}
