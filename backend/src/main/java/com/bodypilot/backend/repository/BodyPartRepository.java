package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.BodyPart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BodyPartRepository extends JpaRepository<BodyPart, UUID> {
    Optional<BodyPart> findByCode(String code);
}
