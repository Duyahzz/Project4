package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "SkillAreas")
public class SkillArea {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer skillAreaId;
    @Column(nullable = false)
    private Integer subjectId;
    @Column(nullable = false, length = 50)
    private String code;
    @Column(nullable = false, length = 150)
    private String name;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String description;
}

