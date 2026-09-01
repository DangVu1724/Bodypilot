package com.bodypilot.backend.repository;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.enums.FoodType;

public interface FoodRepository extends JpaRepository<Food, UUID> {
    
    @EntityGraph(attributePaths = {"category"})
    @Query("SELECT f FROM Food f WHERE LOWER(f.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "AND (:categoryId IS NULL OR f.category.id = :categoryId)")
    Page<Food> searchFoods(@Param("query") String query, @Param("categoryId") UUID categoryId, Pageable pageable);

    @EntityGraph(attributePaths = {"category"})
    @Query("SELECT f FROM Food f WHERE f.type = :type OR f.type = com.bodypilot.backend.model.enums.FoodType.BOTH")
    Page<Food> findByTypeOrBoth(@Param("type") FoodType type, Pageable pageable);

    @EntityGraph(attributePaths = {"category"})
    Page<Food> findByType(FoodType type, Pageable pageable);

    @Query("SELECT f FROM Food f LEFT JOIN FETCH f.category LEFT JOIN FETCH f.recipe")
    java.util.List<Food> findAllWithRelations();

    @Query("SELECT f FROM Food f LEFT JOIN FETCH f.category LEFT JOIN FETCH f.recipe WHERE f.isRecommended = true")
    java.util.List<Food> findAllRecommendedWithRelations();

    @EntityGraph(attributePaths = {"category"})
    @Query("SELECT f FROM Food f")
    java.util.List<Food> findAllWithCategory();

    @EntityGraph(attributePaths = {"category"})
    java.util.List<Food> findByCategoryIdAndIsRecommendedTrue(UUID categoryId);

    @EntityGraph(attributePaths = {"category"})
    java.util.List<Food> findByIsRecommendedTrue();

    long countByType(FoodType type);

    @Query("SELECT new com.bodypilot.backend.model.dto.admin.AdminStatsDTO$CategoryStatItem(" +
           "COALESCE(c.name, 'Khác'), COUNT(f), 0.0) " +
           "FROM Food f LEFT JOIN f.category c " +
           "GROUP BY COALESCE(c.name, 'Khác') ORDER BY COUNT(f) DESC")
    java.util.List<com.bodypilot.backend.model.dto.admin.AdminStatsDTO.CategoryStatItem> findFoodCategoryCounts();
}
