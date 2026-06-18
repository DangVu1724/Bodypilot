package com.bodypilot.backend.model.dto.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserAllergyUpdateRequest {
    private List<String> selectedAllergies;
    private String allergyNote;
}
