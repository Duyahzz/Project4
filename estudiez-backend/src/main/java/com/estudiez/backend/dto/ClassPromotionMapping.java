package com.estudiez.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassPromotionMapping {
    private Integer sourceClassId;
    private Integer targetClassId;
}
