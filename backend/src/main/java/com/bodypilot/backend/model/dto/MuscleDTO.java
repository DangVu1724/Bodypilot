package com.bodypilot.backend.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MuscleDTO {
    private UUID id;
    private String code;
    private String name;
    private String description;
    private UUID bodyPartId;
    private String bodyPartName;
    private String imageUrl;
}
