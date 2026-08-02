package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.nutrition.FoodSmartSwapRequest;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapCandidateDTO;
import com.bodypilot.backend.model.dto.workout.ExerciseSmartSwapRequest;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.service.SmartSwapService;
import com.bodypilot.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/smart-swap")
@RequiredArgsConstructor
public class SmartSwapController {

    private final SmartSwapService smartSwapService;
    private final UserService userService;

    @PostMapping("/food")
    public ResponseEntity<ApiResponse<List<FoodSmartSwapCandidateDTO>>> getFoodSwapCandidates(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody FoodSmartSwapRequest request) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        List<FoodSmartSwapCandidateDTO> candidates = smartSwapService.getFoodSwapCandidates(user, request);
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }

    @PostMapping("/exercise")
    public ResponseEntity<ApiResponse<List<ExerciseSmartSwapCandidateDTO>>> getExerciseSwapCandidates(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ExerciseSmartSwapRequest request) {
        User user = userService.getUserByEmail(userDetails.getUsername());
        List<ExerciseSmartSwapCandidateDTO> candidates = smartSwapService.getExerciseSwapCandidates(user, request);
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }
}
