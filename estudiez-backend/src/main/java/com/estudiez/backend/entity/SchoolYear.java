package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "SchoolYears")
public class SchoolYear {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer schoolYearId;
    @Column(nullable = false, unique = true, length = 30)
    private String name;
    @Column(nullable = false)
    private LocalDate startDate;
    @Column(nullable = false)
    private LocalDate endDate;
    @Column(nullable = false)
    private Boolean isCurrent = false;
}

