package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.nutrition.MealItem;
import com.bodypilot.backend.model.entity.nutrition.MealSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MealItemRepository extends JpaRepository<MealItem, UUID> {
    List<MealItem> findByMealSlotOrderByOrderIndexAsc(MealSlot mealSlot);
}
