package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Classes")
public class SchoolClass {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer classId;
    @Column(nullable = false)
    private Integer schoolYearId;
    @Column(nullable = false)
    private Integer gradeId;
    @Column(nullable = false, length = 50)
    private String name;
    @Column(columnDefinition = "uniqueidentifier")
    private UUID homeroomTeacherId;
    @Column(nullable = false, length = 30)
    private String trainingProgram = "REGULAR";
    @Column(length = 50)
    private String room;
    @Column(nullable = false)
    private Boolean isActive = true;
}

