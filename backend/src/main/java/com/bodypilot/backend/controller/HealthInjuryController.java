package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.entity.HealthCondition;
import com.bodypilot.backend.model.entity.Injury;
import com.bodypilot.backend.model.enums.RecoveryStatus;
import com.bodypilot.backend.model.enums.SeverityLevel;
import com.bodypilot.backend.service.HealthInjuryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class HealthInjuryController {

    private final HealthInjuryService healthInjuryService;

    @GetMapping("/health-conditions")
    public ResponseEntity<List<HealthCondition>> getHealthConditions() {
        return ResponseEntity.ok(healthInjuryService.getAllActiveConditions());
    }

    @GetMapping("/injuries")
    public ResponseEntity<List<Injury>> getInjuries() {
        return ResponseEntity.ok(healthInjuryService.getAllActiveInjuries());
    }

    @PostMapping("/users/{userId}/health-conditions/{conditionId}")
    public ResponseEntity<Void> assignCondition(
            @PathVariable UUID userId,
            @PathVariable UUID conditionId,
            @RequestParam(required = false) SeverityLevel severity,
            @RequestParam(required = false) String note) {
        healthInjuryService.assignConditionToUser(userId, conditionId, severity, note);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/users/{userId}/injuries/{injuryId}")
    public ResponseEntity<Void> assignInjury(
            @PathVariable UUID userId,
            @PathVariable UUID injuryId,
            @RequestParam(required = false) SeverityLevel severity,
            @RequestParam(required = false) RecoveryStatus status,
            @RequestParam(required = false) String note) {
        healthInjuryService.assignInjuryToUser(userId, injuryId, severity, status, note);
        return ResponseEntity.ok().build();
    }
}
