package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Food;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface FoodRepository extends JpaRepository<Food, UUID> {
    
    @Query("SELECT f FROM Food f WHERE LOWER(f.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "AND (:categoryId IS NULL OR f.category.id = :categoryId)")
    Page<Food> searchFoods(@Param("query") String query, @Param("categoryId") UUID categoryId, Pageable pageable);
}
