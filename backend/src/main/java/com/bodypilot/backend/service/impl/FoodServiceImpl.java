package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.exception.ResourceNotFoundException;
import com.bodypilot.backend.model.dto.*;
import com.bodypilot.backend.model.entity.*;
import com.bodypilot.backend.repository.DietTagRepository;
import com.bodypilot.backend.repository.FoodCategoryRepository;
import com.bodypilot.backend.repository.FoodRepository;
import com.bodypilot.backend.service.FoodService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FoodServiceImpl implements FoodService {

    private final FoodRepository foodRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final DietTagRepository dietTagRepository;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<FoodSummaryResponse> searchFoods(String query, UUID categoryId, Pageable pageable) {
        Page<Food> foodPage = foodRepository.searchFoods(query, categoryId, pageable);
        List<FoodSummaryResponse> content = foodPage.getContent().stream()
                .map(this::mapToSummary)
                .collect(Collectors.toList());
        return PageResponse.fromPage(foodPage, content);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<FoodSummaryResponse> getFoodsByType(String type, Pageable pageable) {
        com.bodypilot.backend.model.enums.FoodType foodType = com.bodypilot.backend.model.enums.FoodType.valueOf(type.toUpperCase());
        Page<Food> foodPage = foodRepository.findByType(foodType, pageable);
        List<FoodSummaryResponse> content = foodPage.getContent().stream()
                .map(this::mapToSummary)
                .collect(Collectors.toList());
        return PageResponse.fromPage(foodPage, content);
    }

    @Override
    @Transactional(readOnly = true)
    public FoodResponse getFoodById(UUID id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Food not found with id: " + id));
        return mapToResponse(food);
    }

    @Override
    @Transactional(readOnly = true)
    public List<FoodCategoryDTO> getAllCategories() {
        return foodCategoryRepository.findAll().stream()
                .map(this::mapToCategoryDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<DietTagDTO> getDietTags() {
        return dietTagRepository.findAll().stream()
                .map(this::mapToDietTagDTO)
                .collect(Collectors.toList());
    }

    private FoodSummaryResponse mapToSummary(Food food) {
        return FoodSummaryResponse.builder()
                .id(food.getId())
                .name(food.getName())
                .type(food.getType())
                .caloriesPer100g(food.getCaloriesPer100g())
                .proteinPer100g(food.getProteinPer100g())
                .fatPer100g(food.getFatPer100g())
                .carbsPer100g(food.getCarbsPer100g())
                .imageUrl(food.getImageUrl())
                .categoryName(food.getCategory() != null ? food.getCategory().getName() : null)
                .healthScore(food.getHealthScore())
                .build();
    }

    private FoodResponse mapToResponse(Food food) {
        return FoodResponse.builder()
                .id(food.getId())
                .name(food.getName())
                .type(food.getType())
                .caloriesPer100g(food.getCaloriesPer100g())
                .proteinPer100g(food.getProteinPer100g())
                .fatPer100g(food.getFatPer100g())
                .carbsPer100g(food.getCarbsPer100g())
                .fiberPer100g(food.getFiberPer100g())
                .sugarPer100g(food.getSugarPer100g())
                .sodiumMgPer100g(food.getSodiumMgPer100g())
                .category(mapToCategoryDTO(food.getCategory()))
                .defaultServingSize(food.getDefaultServingSize())
                .defaultUnit(food.getDefaultUnit())
                .imageUrl(food.getImageUrl())
                .description(food.getDescription())
                .healthScore(food.getHealthScore())
                .servings(food.getServings().stream().map(this::mapToServingDTO).collect(Collectors.toList()))
                .dietTags(food.getDietTags().stream().map(this::mapToDietTagDTO).collect(Collectors.toList()))
                .recipe(mapToRecipeDTO(food.getRecipe()))
                .build();
    }

    private FoodCategoryDTO mapToCategoryDTO(FoodCategory category) {
        if (category == null) return null;
        return FoodCategoryDTO.builder()
                .id(category.getId())
                .name(category.getName())
                .code(category.getCode())
                .appliesTo(category.getAppliesTo())
                .build();
    }

    private FoodServingDTO mapToServingDTO(FoodServing serving) {
        return FoodServingDTO.builder()
                .id(serving.getId())
                .name(serving.getName())
                .grams(serving.getGrams())
                .isDefault(serving.isDefault())
                .build();
    }

    private DietTagDTO mapToDietTagDTO(DietTag tag) {
        return DietTagDTO.builder()
                .id(tag.getId())
                .name(tag.getName())
                .description(tag.getDescription())
                .build();
    }

    private RecipeDTO mapToRecipeDTO(Recipe recipe) {
        if (recipe == null) return null;
        return RecipeDTO.builder()
                .id(recipe.getId())
                .servings(recipe.getServings())
                .cookingTimeMinutes(recipe.getCookingTimeMinutes())
                .instructions(recipe.getInstructions())
                .ingredients(recipe.getIngredients().stream().map(this::mapToIngredientDTO).collect(Collectors.toList()))
                .build();
    }

    private RecipeIngredientDTO mapToIngredientDTO(RecipeIngredient ingredient) {
        return RecipeIngredientDTO.builder()
                .id(ingredient.getId())
                .foodId(ingredient.getFood().getId())
                .foodName(ingredient.getFood().getName())
                .quantityGrams(ingredient.getQuantityGrams())
                .build();
    }

    @Override
    @Transactional
    public FoodResponse createFood(com.bodypilot.backend.model.dto.FoodRequest request) {
        Food food = new Food();
        updateFoodFromRequest(food, request);
        Food savedFood = foodRepository.save(food);
        return mapToResponse(savedFood);
    }

    @Override
    @Transactional
    public FoodResponse updateFood(UUID id, com.bodypilot.backend.model.dto.FoodRequest request) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Food not found with id: " + id));
        updateFoodFromRequest(food, request);
        Food savedFood = foodRepository.save(food);
        return mapToResponse(savedFood);
    }

    @Override
    @Transactional
    public void deleteFood(UUID id) {
        if (!foodRepository.existsById(id)) {
            throw new ResourceNotFoundException("Food not found with id: " + id);
        }
        foodRepository.deleteById(id);
    }

    private void updateFoodFromRequest(Food food, com.bodypilot.backend.model.dto.FoodRequest request) {
        food.setName(request.getName());
        if (request.getType() != null) {
            food.setType(com.bodypilot.backend.model.enums.FoodType.valueOf(request.getType()));
        }
        food.setCaloriesPer100g(BigDecimal.valueOf(request.getCaloriesPer100g()));
        food.setProteinPer100g(BigDecimal.valueOf(request.getProteinPer100g()));
        food.setFatPer100g(BigDecimal.valueOf(request.getFatPer100g()));
        food.setCarbsPer100g(BigDecimal.valueOf(request.getCarbsPer100g()));
        food.setFiberPer100g(BigDecimal.valueOf(request.getFiberPer100g()));
        food.setSugarPer100g(BigDecimal.valueOf(request.getSugarPer100g()));
        food.setSodiumMgPer100g(BigDecimal.valueOf(request.getSodiumMgPer100g()));
        food.setDefaultServingSize(BigDecimal.valueOf(request.getDefaultServingSize()));
        food.setDefaultUnit(request.getDefaultUnit());
        food.setImageUrl(request.getImageUrl());
        food.setDescription(request.getDescription());
        food.setHealthScore(request.getHealthScore());

        if (request.getCategoryId() != null) {
            food.setCategory(foodCategoryRepository.findById(request.getCategoryId()).orElse(null));
        } else {
            food.setCategory(null);
        }

        if (food.getType() == com.bodypilot.backend.model.enums.FoodType.DISH && request.getRecipe() != null) {
            Recipe recipe = food.getRecipe();
            if (recipe == null) {
                recipe = new Recipe();
                recipe.setFood(food);
                food.setRecipe(recipe);
            }
            recipe.setServings(request.getRecipe().getServings() != null ? request.getRecipe().getServings() : 1);
            recipe.setCookingTimeMinutes(request.getRecipe().getCookingTimeMinutes());
            recipe.setInstructions(request.getRecipe().getInstructions());

            if (request.getRecipe().getIngredients() != null) {
                recipe.getIngredients().clear();
                for (com.bodypilot.backend.model.dto.RecipeIngredientRequest riReq : request.getRecipe().getIngredients()) {
                    Food ingredientFood = foodRepository.findById(riReq.getFoodId())
                            .orElseThrow(() -> new ResourceNotFoundException("Ingredient not found: " + riReq.getFoodId()));
                    RecipeIngredient ri = new RecipeIngredient();
                    ri.setRecipe(recipe);
                    ri.setFood(ingredientFood);
                    ri.setQuantityGrams(riReq.getQuantityGrams() != null ? BigDecimal.valueOf(riReq.getQuantityGrams()) : BigDecimal.ZERO);
                    recipe.getIngredients().add(ri);
                }
            }
        } else if (food.getType() == com.bodypilot.backend.model.enums.FoodType.INGREDIENT) {
            // Remove recipe if it's an ingredient
            if (food.getRecipe() != null) {
                food.setRecipe(null);
            }
        }
    }
}
