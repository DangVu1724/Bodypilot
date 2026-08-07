package com.bodypilot.backend.repository;

import com.bodypilot.backend.model.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u LEFT JOIN u.profile p WHERE (:query IS NULL OR :query = '' OR LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%')) OR (p.fullName IS NOT NULL AND LOWER(p.fullName) LIKE LOWER(CONCAT('%', :query, '%'))))")
    java.util.List<User> searchUsers(@org.springframework.data.repository.query.Param("query") String query);
}
