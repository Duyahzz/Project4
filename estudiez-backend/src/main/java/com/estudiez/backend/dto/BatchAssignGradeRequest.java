package com.estudiez.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BatchAssignGradeRequest {
    private List<UUID> studentIds;
    private Integer gradeLevel;
    private Integer targetClassId;
    private Integer schoolYearId;
}
