package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Subjects")
public class Subject {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer subjectId;
    @Column(nullable = false, unique = true, length = 30)
    private String code;
    @Column(nullable = false, length = 120)
    private String name;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String description;
    @Column(nullable = false)
    private Boolean isActive = true;
}

