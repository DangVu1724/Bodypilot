package com.bodypilot.backend.security;

import com.bodypilot.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.access.intercept.RequestAuthorizationContext;
import org.springframework.stereotype.Component;

import java.util.UUID;
import java.util.function.Supplier;

@Component
@RequiredArgsConstructor
public class UserSecurity {

    private final UserRepository userRepository;

    public AuthorizationDecision checkOwnerOrAdmin(
            Supplier<? extends Authentication> authenticationSupplier,
            RequestAuthorizationContext context) {
        Authentication auth = authenticationSupplier.get();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return new AuthorizationDecision(false);
        }

        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
        if (isAdmin) {
            return new AuthorizationDecision(true);
        }

        String userIdStr = context.getVariables().get("userId");
        if (userIdStr == null || userIdStr.isBlank()) {
            return new AuthorizationDecision(false);
        }

        try {
            UUID targetUserId = UUID.fromString(userIdStr);
            String email = auth.getName();
            boolean isOwner = userRepository.findByEmail(email)
                    .map(user -> user.getId().equals(targetUserId))
                    .orElse(false);
            return new AuthorizationDecision(isOwner);
        } catch (IllegalArgumentException e) {
            return new AuthorizationDecision(false);
        }
    }
}
