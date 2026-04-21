package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.Injury;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InjuryRepository extends JpaRepository<Injury, UUID> {
    List<Injury> findAllByIsActiveTrue();
    Optional<Injury> findByCode(String code);
}
