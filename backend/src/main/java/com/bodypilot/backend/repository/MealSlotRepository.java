package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.nutrition.DailyEating;
import com.bodypilot.backend.model.entity.nutrition.MealSlot;
import com.bodypilot.backend.model.enums.MealType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MealSlotRepository extends JpaRepository<MealSlot, UUID> {
    Optional<MealSlot> findByDailyEatingAndMealType(DailyEating dailyEating, MealType mealType);
}
