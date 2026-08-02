package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapRequest;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapRequest;
import com.bodypilot.backend.model.entity.user.User;

import java.util.List;

public interface SmartSwapService {
    List<FoodSmartSwapCandidateDTO> getFoodSwapCandidates(User user, FoodSmartSwapRequest request);
    List<ExerciseSmartSwapCandidateDTO> getExerciseSwapCandidates(User user, ExerciseSmartSwapRequest request);
}
