package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.nutrition.DailyEatingDTO;
import com.bodypilot.backend.model.dto.nutrition.MealItemDTO;
import com.bodypilot.backend.model.dto.nutrition.MealSlotDTO;
import com.bodypilot.backend.model.entity.nutrition.DailyEating;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.nutrition.MealItem;
import com.bodypilot.backend.model.entity.nutrition.MealSlot;
import com.bodypilot.backend.model.entity.user.User;
import com.bodypilot.backend.model.enums.MealType;
import com.bodypilot.backend.repository.DailyEatingRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.repository.MealItemRepository;
import com.bodypilot.backend.repository.MealSlotRepository;
import com.bodypilot.backend.service.NutritionDiaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NutritionDiaryServiceImpl implements NutritionDiaryService {

    private final DailyEatingRepository dailyEatingRepository;
    private final MealSlotRepository mealSlotRepository;
    private final MealItemRepository mealItemRepository;
    private final FoodRepository foodRepository;

    @Override
    @Transactional(readOnly = true)
    public DailyEatingDTO getDailyEating(User user, LocalDate date) {
        DailyEating dailyEating = dailyEatingRepository.findByUserAndDate(user, date)
                .orElseGet(() -> DailyEating.builder().user(user).date(date).build());
        return mapToDailyEatingDTO(dailyEating);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DailyEatingDTO> getDailyEatingRange(User user, LocalDate startDate, LocalDate endDate) {
        return dailyEatingRepository.findByUserAndDateBetweenOrderByDateAsc(user, startDate, endDate)
                .stream()
                .map(this::mapToDailyEatingDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public DailyEatingDTO addFoodToDiary(User user, LocalDate date, MealType mealType, MealItemDTO itemDTO) {
        DailyEating dailyEating = dailyEatingRepository.findByUserAndDate(user, date)
                .orElseGet(() -> dailyEatingRepository.save(DailyEating.builder()
                        .user(user)
                        .date(date)
                        .isAiGenerated(itemDTO.getIsCustom() != null && !itemDTO.getIsCustom()) // Simplified logic
                        .build()));

        MealSlot mealSlot = mealSlotRepository.findByDailyEatingAndMealType(dailyEating, mealType)
                .orElseGet(() -> mealSlotRepository.save(MealSlot.builder()
                        .dailyEating(dailyEating)
                        .mealType(mealType)
                        .orderIndex(mealType.ordinal())
                        .build()));

        MealItem mealItem = new MealItem();
        mealItem.setMealSlot(mealSlot);
        mealItem.setServingQuantity(itemDTO.getServingQuantity());
        mealItem.setOrderIndex(itemDTO.getOrderIndex() != null ? itemDTO.getOrderIndex() : mealSlot.getItems().size());

        if (itemDTO.getFoodId() != null) {
            Food food = foodRepository.findById(itemDTO.getFoodId())
                    .orElseThrow(() -> new ResourceNotFoundException("Food not found"));
            mealItem.setFood(food);
            snapshotFoodData(mealItem, food, itemDTO.getServingQuantity());
        } else {
            // Custom food data from DTO
            mealItem.setIsCustom(true);
            mealItem.setFoodNameSnapshot(itemDTO.getFoodName());
            mealItem.setCaloriesSnapshot(itemDTO.getCalories());
            mealItem.setProteinSnapshot(itemDTO.getProtein());
            mealItem.setFatSnapshot(itemDTO.getFat());
            mealItem.setCarbsSnapshot(itemDTO.getCarbs());
            mealItem.setFiberSnapshot(itemDTO.getFiber());
            mealItem.setServingUnitSnapshot(itemDTO.getServingUnit());
            mealItem.setImageUrlSnapshot(itemDTO.getImageUrl());
        }

        mealItemRepository.save(mealItem);
        mealSlot.getItems().add(mealItem);
        recalculateDailyCalories(dailyEating);
        return mapToDailyEatingDTO(dailyEating);
    }

    @Override
    @Transactional
    public void removeFoodFromDiary(UUID mealItemId) {
        MealItem mealItem = mealItemRepository.findById(mealItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Meal item not found"));
        DailyEating dailyEating = mealItem.getMealSlot().getDailyEating();
        mealItem.getMealSlot().getItems().remove(mealItem);
        mealItemRepository.delete(mealItem);
        recalculateDailyCalories(dailyEating);
    }

    @Override
    @Transactional
    public void updateFoodInDiary(UUID mealItemId, MealItemDTO itemDTO) {
        MealItem mealItem = mealItemRepository.findById(mealItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Meal item not found"));

        mealItem.setServingQuantity(itemDTO.getServingQuantity());
        if (itemDTO.getOrderIndex() != null) {
            mealItem.setOrderIndex(itemDTO.getOrderIndex());
        }

        if (mealItem.getFood() != null) {
            // Re-snapshot based on new quantity
            snapshotFoodData(mealItem, mealItem.getFood(), itemDTO.getServingQuantity());
        } else {
            // Update custom data
            mealItem.setFoodNameSnapshot(itemDTO.getFoodName());
            mealItem.setCaloriesSnapshot(itemDTO.getCalories());
            mealItem.setProteinSnapshot(itemDTO.getProtein());
            mealItem.setFatSnapshot(itemDTO.getFat());
            mealItem.setCarbsSnapshot(itemDTO.getCarbs());
            mealItem.setFiberSnapshot(itemDTO.getFiber());
            mealItem.setServingUnitSnapshot(itemDTO.getServingUnit());
        }

        mealItemRepository.save(mealItem);
        recalculateDailyCalories(mealItem.getMealSlot().getDailyEating());
    }

    @Override
    @Transactional
    public void reorderMealItems(UUID mealSlotId, List<UUID> itemIds) {
        MealSlot mealSlot = mealSlotRepository.findById(mealSlotId)
                .orElseThrow(() -> new ResourceNotFoundException("Meal slot not found"));

        List<MealItem> items = mealSlot.getItems();
        for (int i = 0; i < itemIds.size(); i++) {
            UUID itemId = itemIds.get(i);
            int orderIndex = i;
            items.stream()
                    .filter(item -> item.getId().equals(itemId))
                    .findFirst()
                    .ifPresent(item -> item.setOrderIndex(orderIndex));
        }
        mealItemRepository.saveAll(items);
    }

    @Override
    @Transactional
    public void clearMeal(User user, LocalDate date, MealType mealType) {
        dailyEatingRepository.findByUserAndDate(user, date)
                .ifPresent(dailyEating -> mealSlotRepository.findByDailyEatingAndMealType(dailyEating, mealType)
                        .ifPresent(mealSlot -> {
                            mealSlot.getItems().clear();
                            mealSlotRepository.save(mealSlot);
                            recalculateDailyCalories(dailyEating);
                        }));
    }

    @Override
    @Transactional
    public void clearDay(User user, LocalDate date) {
        dailyEatingRepository.findByUserAndDate(user, date)
                .ifPresent(dailyEatingRepository::delete);
    }

    @Override
    @Transactional
    public void updateDailyNote(User user, LocalDate date, String note) {
        DailyEating dailyEating = dailyEatingRepository.findByUserAndDate(user, date)
                .orElseGet(() -> dailyEatingRepository.save(DailyEating.builder()
                        .user(user)
                        .date(date)
                        .build()));
        dailyEating.setNote(note);
        dailyEatingRepository.save(dailyEating);
    }

    @Override
    @Transactional
    public void addMultipleDailyEatings(User user, List<DailyEatingDTO> dailyEatingDTOs) {
        for (DailyEatingDTO dayDto : dailyEatingDTOs) {
            DailyEating dailyEating = dailyEatingRepository.findByUserAndDate(user, dayDto.getDate())
                    .orElseGet(() -> DailyEating.builder()
                            .user(user)
                            .date(dayDto.getDate())
                            .build());

            dailyEating.setNote(dayDto.getNote());
            dailyEating.setIsAiGenerated(dayDto.getIsAiGenerated());

            // Clear existing slots if we are overwriting
            dailyEating.getMealSlots().clear();
            DailyEating savedDay = dailyEatingRepository.save(dailyEating);

            if (dayDto.getMealSlots() != null) {
                for (MealSlotDTO slotDto : dayDto.getMealSlots()) {
                    MealSlot mealSlot = MealSlot.builder()
                            .dailyEating(savedDay)
                            .mealType(slotDto.getMealType())
                            .customName(slotDto.getCustomName())
                            .orderIndex(slotDto.getOrderIndex())
                            .build();

                    MealSlot savedSlot = mealSlotRepository.save(mealSlot);

                    if (slotDto.getItems() != null) {
                        for (MealItemDTO itemDto : slotDto.getItems()) {
                            MealItem item = new MealItem();
                            item.setMealSlot(savedSlot);
                            item.setServingQuantity(itemDto.getServingQuantity());
                            item.setOrderIndex(itemDto.getOrderIndex());
                            item.setIsCustom(itemDto.getIsCustom());

                            if (itemDto.getFoodId() != null) {
                                foodRepository.findById(itemDto.getFoodId())
                                        .ifPresent(food -> {
                                            item.setFood(food);
                                            snapshotFoodData(item, food, itemDto.getServingQuantity());
                                        });
                            } else {
                                item.setFoodNameSnapshot(itemDto.getFoodName());
                                item.setCaloriesSnapshot(itemDto.getCalories());
                                item.setProteinSnapshot(itemDto.getProtein());
                                item.setFatSnapshot(itemDto.getFat());
                                item.setCarbsSnapshot(itemDto.getCarbs());
                                item.setFiberSnapshot(itemDto.getFiber());
                                item.setServingUnitSnapshot(itemDto.getServingUnit());
                                item.setImageUrlSnapshot(itemDto.getImageUrl());
                            }
                            mealItemRepository.save(item);
                            savedSlot.getItems().add(item);
                        }
                    }
                }
            }
            recalculateDailyCalories(savedDay);
        }
    }

    @Override
    @Transactional
    public DailyEatingDTO updateMealItemStatus(UUID mealItemId, Boolean isEaten) {
        MealItem mealItem = mealItemRepository.findById(mealItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Meal item not found"));
        mealItem.setIsEaten(isEaten);
        mealItemRepository.save(mealItem);

        DailyEating dailyEating = mealItem.getMealSlot().getDailyEating();
        recalculateDailyCalories(dailyEating);
        return mapToDailyEatingDTO(dailyEating);
    }

    @Override
    @Transactional
    public DailyEatingDTO updateMealSlotStatus(UUID mealSlotId, Boolean isEaten) {
        MealSlot mealSlot = mealSlotRepository.findById(mealSlotId)
                .orElseThrow(() -> new ResourceNotFoundException("Meal slot not found"));
        mealSlot.setIsEaten(isEaten);
        for (MealItem item : mealSlot.getItems()) {
            item.setIsEaten(isEaten);
        }
        mealItemRepository.saveAll(mealSlot.getItems());
        mealSlotRepository.save(mealSlot);

        DailyEating dailyEating = mealSlot.getDailyEating();
        recalculateDailyCalories(dailyEating);
        return mapToDailyEatingDTO(dailyEating);
    }

    private void recalculateDailyCalories(DailyEating dailyEating) {
        BigDecimal totalPlanned = BigDecimal.ZERO;
        BigDecimal totalEaten = BigDecimal.ZERO;

        for (MealSlot slot : dailyEating.getMealSlots()) {
            boolean allItemsEaten = !slot.getItems().isEmpty();
            for (MealItem item : slot.getItems()) {
                BigDecimal itemCal = item.getCaloriesSnapshot() != null ? item.getCaloriesSnapshot() : BigDecimal.ZERO;
                totalPlanned = totalPlanned.add(itemCal);

                if (Boolean.TRUE.equals(item.getIsEaten())) {
                    totalEaten = totalEaten.add(itemCal);
                } else {
                    allItemsEaten = false;
                }
            }
            slot.setIsEaten(allItemsEaten);
            mealSlotRepository.save(slot);
        }
        dailyEating.setTotalCaloriesPlanned(totalPlanned);
        dailyEating.setTotalCaloriesEaten(totalEaten);
        dailyEatingRepository.save(dailyEating);
    }

    private void snapshotFoodData(MealItem mealItem, Food food, BigDecimal quantity) {
        // Assuming quantity is in grams for simplicity in this initial version
        // In a full implementation, we'd handle different serving units
        BigDecimal ratio = quantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);

        mealItem.setFoodNameSnapshot(food.getName());
        mealItem.setCaloriesSnapshot(food.getCaloriesPer100g().multiply(ratio));
        mealItem.setProteinSnapshot(food.getProteinPer100g().multiply(ratio));
        mealItem.setFatSnapshot(food.getFatPer100g().multiply(ratio));
        mealItem.setCarbsSnapshot(food.getCarbsPer100g().multiply(ratio));
        mealItem.setFiberSnapshot(food.getFiberPer100g().multiply(ratio));
        mealItem.setImageUrlSnapshot(food.getImageUrl());

        if (food.getDefaultServing() != null) {
            mealItem.setServingUnitSnapshot(food.getDefaultServing().getName());
        } else {
            mealItem.setServingUnitSnapshot("grams");
        }
    }

    private DailyEatingDTO mapToDailyEatingDTO(DailyEating dailyEating) {
        return DailyEatingDTO.builder()
                .id(dailyEating.getId())
                .date(dailyEating.getDate())
                .note(dailyEating.getNote())
                .isAiGenerated(dailyEating.getIsAiGenerated())
                .totalCaloriesPlanned(dailyEating.getTotalCaloriesPlanned())
                .totalCaloriesEaten(dailyEating.getTotalCaloriesEaten())
                .mealSlots(dailyEating.getMealSlots().stream()
                        .map(this::mapToMealSlotDTO)
                        .collect(Collectors.toList()))
                .build();
    }

    private MealSlotDTO mapToMealSlotDTO(MealSlot mealSlot) {
        return MealSlotDTO.builder()
                .id(mealSlot.getId())
                .mealType(mealSlot.getMealType())
                .customName(mealSlot.getCustomName())
                .orderIndex(mealSlot.getOrderIndex())
                .isEaten(mealSlot.getIsEaten())
                .items(mealSlot.getItems().stream()
                        .map(this::mapToMealItemDTO)
                        .collect(Collectors.toList()))
                .build();
    }

    private MealItemDTO mapToMealItemDTO(MealItem mealItem) {
        return MealItemDTO.builder()
                .id(mealItem.getId())
                .foodId(mealItem.getFood() != null ? mealItem.getFood().getId() : null)
                .servingQuantity(mealItem.getServingQuantity())
                .orderIndex(mealItem.getOrderIndex())
                .foodName(mealItem.getFoodNameSnapshot())
                .calories(mealItem.getCaloriesSnapshot())
                .protein(mealItem.getProteinSnapshot())
                .fat(mealItem.getFatSnapshot())
                .carbs(mealItem.getCarbsSnapshot())
                .fiber(mealItem.getFiberSnapshot())
                .servingUnit(mealItem.getServingUnitSnapshot())
                .imageUrl(mealItem.getImageUrlSnapshot())
                .isCustom(mealItem.getIsCustom())
                .isEaten(mealItem.getIsEaten())
                .build();
    }
}
