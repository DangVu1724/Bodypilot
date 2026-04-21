package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.HealthCondition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HealthConditionRepository extends JpaRepository<HealthCondition, UUID> {
    List<HealthCondition> findAllByIsActiveTrue();
    Optional<HealthCondition> findByCode(String code);
}
