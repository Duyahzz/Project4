package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Semesters")
public class Semester {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer semesterId;
    @Column(nullable = false)
    private Integer schoolYearId;
    @Column(nullable = false, length = 50)
    private String name;
    @Column(nullable = false)
    private LocalDate startDate;
    @Column(nullable = false)
    private LocalDate endDate;
}

