package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Grades")
public class Grade {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer gradeId;
    @Column(nullable = false, unique = true, length = 10)
    private String code;
    @Column(nullable = false, length = 50)
    private String name;
}

