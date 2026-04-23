package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.DietTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface DietTagRepository extends JpaRepository<DietTag, UUID> {
}
