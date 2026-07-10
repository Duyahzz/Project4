package com.estudiez.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BatchPromotionRequest {
    private Integer sourceSchoolYearId;
    private Integer targetSchoolYearId;
    private List<ClassPromotionMapping> classMappings;
    private List<UUID> studentIds;
}
