package com.bodypilot.backend.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.bodypilot.backend.model.entity.health.AllergyMaster;

@Repository
public interface AllergyMasterRepository extends JpaRepository<AllergyMaster, UUID> {
    List<AllergyMaster> findAllByIsActiveTrue();

    Optional<AllergyMaster> findByCode(String code);
}
