package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.FoodCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, UUID> {
}
