package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.user.UserAllergyUpdateRequest;
import com.bodypilot.backend.model.dto.user.UserPreferencesUpdateRequest;
import com.bodypilot.backend.model.entity.health.HealthCondition;
import com.bodypilot.backend.model.entity.health.Injury;
import com.bodypilot.backend.model.entity.user.*;
import com.bodypilot.backend.model.entity.health.AllergyMaster;
import com.bodypilot.backend.model.entity.nutrition.DietTag;
import com.bodypilot.backend.model.enums.FoodBudget;
import com.bodypilot.backend.model.enums.DislikedFoodGroup;
import com.bodypilot.backend.model.enums.RecoveryStatus;
import com.bodypilot.backend.model.enums.SeverityLevel;
import com.bodypilot.backend.repository.*;
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
    private final AllergyMasterRepository allergyMasterRepository;
    private final UserAllergyRepository userAllergyRepository;
    private final UserDietPreferenceRepository userDietPreferenceRepository;
    private final DietTagRepository dietTagRepository;
    private final UserFoodPreferenceRepository userFoodPreferenceRepository;
    private final UserProfileRepository userProfileRepository;

    public List<HealthCondition> getAllActiveConditions() {
        return conditionRepository.findAllByIsActiveTrue();
    }

    public List<Injury> getAllActiveInjuries() {
        return injuryRepository.findAllByIsActiveTrue();
    }

    public List<AllergyMaster> getAllActiveAllergies() {
        return allergyMasterRepository.findAllByIsActiveTrue();
    }

    @Transactional
    public void assignAllergyToUser(UUID userId, UUID allergyId, SeverityLevel severity, String note) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        AllergyMaster allergy = allergyMasterRepository.findById(allergyId)
                .orElseThrow(() -> new RuntimeException("Allergy master option not found"));

        UserAllergy userAllergy = userAllergyRepository.findByUserAndAllergyMaster(user, allergy)
                .orElse(UserAllergy.builder().user(user).allergyMaster(allergy).build());

        userAllergy.setSeverity(severity != null ? severity : SeverityLevel.MEDIUM);
        userAllergy.setNote(note);
        userAllergyRepository.save(userAllergy);
    }

    @Transactional
    public void updateUserAllergies(UUID userId, UserAllergyUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Set existing allergies to inactive to override
        List<UserAllergy> existingAllergies = userAllergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        for (UserAllergy allergy : existingAllergies) {
            allergy.setIsActive(false);
            userAllergyRepository.save(allergy);
        }

        // Add new ones
        if (request.getSelectedAllergies() != null) {
            for (String allergyCode : request.getSelectedAllergies()) {
                allergyMasterRepository.findByCode(allergyCode)
                        .ifPresent(am -> {
                            UserAllergy userAllergy = userAllergyRepository.findByUserAndAllergyMaster(user, am)
                                    .orElse(UserAllergy.builder().user(user).allergyMaster(am).build());
                            userAllergy.setSeverity(SeverityLevel.MEDIUM);
                            userAllergy.setNote(request.getAllergyNote());
                            userAllergy.setIsActive(true);
                            userAllergyRepository.save(userAllergy);
                        });
            }
        }
    }

    @Transactional
    public void updateUserPreferences(UUID userId, UserPreferencesUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 1. Update Allergies
        List<UserAllergy> existingAllergies = userAllergyRepository.findAllByUserIdAndIsActiveTrue(userId);
        for (UserAllergy allergy : existingAllergies) {
            allergy.setIsActive(false);
            userAllergyRepository.save(allergy);
        }

        if (request.getSelectedAllergies() != null) {
            for (String allergyCode : request.getSelectedAllergies()) {
                allergyMasterRepository.findByCode(allergyCode)
                        .ifPresent(am -> {
                            UserAllergy userAllergy = userAllergyRepository.findByUserAndAllergyMaster(user, am)
                                    .orElse(UserAllergy.builder().user(user).allergyMaster(am).build());
                            userAllergy.setSeverity(SeverityLevel.MEDIUM);
                            userAllergy.setNote(request.getAllergyNote());
                            userAllergy.setIsActive(true);
                            userAllergyRepository.save(userAllergy);
                        });
            }
        }

        // 2. Update Food Budget in UserProfile
        UserProfile profile = userProfileRepository.findByUserId(userId)
                .orElse(UserProfile.builder().user(user).build());
        if (request.getFoodBudget() != null) {
            try {
                profile.setFoodBudget(FoodBudget.valueOf(request.getFoodBudget().toUpperCase()));
            } catch (Exception e) {
                // Ignore invalid enums
            }
        }
        userProfileRepository.save(profile);

        // 3. Update Diet Preferences
        if (request.getSelectedDietTagId() != null) {
            List<UserDietPreference> existingDiets = userDietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
            for (UserDietPreference dp : existingDiets) {
                dp.setIsActive(false);
                userDietPreferenceRepository.save(dp);
            }

            dietTagRepository.findById(request.getSelectedDietTagId())
                    .ifPresent(dt -> {
                        UserDietPreference dietPreference = userDietPreferenceRepository.findByUserAndDietTag(user, dt)
                                .orElse(UserDietPreference.builder().user(user).dietTag(dt).build());
                        dietPreference.setIsActive(true);
                        userDietPreferenceRepository.save(dietPreference);
                    });
        } else {
            List<UserDietPreference> existingDiets = userDietPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
            for (UserDietPreference dp : existingDiets) {
                dp.setIsActive(false);
                userDietPreferenceRepository.save(dp);
            }
        }

        // 4. Update Disliked Foods
        List<UserFoodPreference> existingPrefs = userFoodPreferenceRepository.findAllByUserIdAndIsActiveTrue(userId);
        for (UserFoodPreference fp : existingPrefs) {
            fp.setIsActive(false);
            userFoodPreferenceRepository.save(fp);
        }

        if (request.getDislikedFoodGroups() != null) {
            for (String groupStr : request.getDislikedFoodGroups()) {
                try {
                    DislikedFoodGroup group = DislikedFoodGroup.valueOf(groupStr.toUpperCase());
                    UserFoodPreference pref = userFoodPreferenceRepository.findByUserAndDislikedFoodGroup(user, group)
                            .orElse(UserFoodPreference.builder().user(user).dislikedFoodGroup(group).build());
                    pref.setIsActive(true);
                    pref.setNote(request.getDislikedFoodsNote());
                    userFoodPreferenceRepository.save(pref);
                } catch (Exception e) {
                    // Ignore invalid enums
                }
            }
        }
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
