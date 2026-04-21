package com.bodypilot.backend.service;

import com.bodypilot.backend.model.entity.HealthCondition;
import com.bodypilot.backend.model.entity.Injury;
import com.bodypilot.backend.model.entity.User;
import com.bodypilot.backend.model.entity.UserHealthCondition;
import com.bodypilot.backend.model.entity.UserInjury;
import com.bodypilot.backend.model.enums.RecoveryStatus;
import com.bodypilot.backend.model.enums.SeverityLevel;
import com.bodypilot.backend.repository.HealthConditionRepository;
import com.bodypilot.backend.repository.InjuryRepository;
import com.bodypilot.backend.repository.UserHealthConditionRepository;
import com.bodypilot.backend.repository.UserInjuryRepository;
import com.bodypilot.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HealthInjuryService {

    private final HealthConditionRepository conditionRepository;
    private final InjuryRepository injuryRepository;
    private final UserHealthConditionRepository userConditionRepository;
    private final UserInjuryRepository userInjuryRepository;
    private final UserRepository userRepository;

    public List<HealthCondition> getAllActiveConditions() {
        return conditionRepository.findAllByIsActiveTrue();
    }

    public List<Injury> getAllActiveInjuries() {
        return injuryRepository.findAllByIsActiveTrue();
    }

    @Transactional
    public void assignConditionToUser(UUID userId, UUID conditionId, SeverityLevel severity, String note) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        HealthCondition condition = conditionRepository.findById(conditionId)
                .orElseThrow(() -> new RuntimeException("Condition not found"));

        UserHealthCondition userCondition = userConditionRepository.findByUserAndCondition(user, condition)
                .orElse(UserHealthCondition.builder().user(user).condition(condition).build());

        userCondition.setSeverityOverride(severity);
        userCondition.setNote(note);
        userConditionRepository.save(userCondition);
    }

    @Transactional
    public void assignInjuryToUser(UUID userId, UUID injuryId, SeverityLevel severity, RecoveryStatus status, String note) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Injury injury = injuryRepository.findById(injuryId)
                .orElseThrow(() -> new RuntimeException("Injury not found"));

        UserInjury userInjury = userInjuryRepository.findByUserAndInjury(user, injury)
                .orElse(UserInjury.builder().user(user).injury(injury).build());

        userInjury.setSeverityOverride(severity);
        userInjury.setRecoveryStatus(status);
        userInjury.setNote(note);
        userInjuryRepository.save(userInjury);
    }
}
