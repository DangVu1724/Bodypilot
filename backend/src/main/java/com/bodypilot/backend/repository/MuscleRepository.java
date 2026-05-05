package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Muscle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MuscleRepository extends JpaRepository<Muscle, UUID> {
    Optional<Muscle> findByCode(String code);
    List<Muscle> findByBodyPartId(UUID bodyPartId);
}
