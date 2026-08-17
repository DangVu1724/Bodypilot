package com.bodypilot.backend.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.bodypilot.backend.model.entity.workout.BodyPart;

@Repository
public interface BodyPartRepository extends JpaRepository<BodyPart, UUID> {
    Optional<BodyPart> findByCode(String code);
}
