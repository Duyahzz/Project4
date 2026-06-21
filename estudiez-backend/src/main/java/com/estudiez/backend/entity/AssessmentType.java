package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "AssessmentTypes")
public class AssessmentType {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer assessmentTypeId;
    @Column(nullable = false, unique = true, length = 30)
    private String code;
    @Column(nullable = false, length = 100)
    private String name;
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal defaultWeight = BigDecimal.ONE;
}

