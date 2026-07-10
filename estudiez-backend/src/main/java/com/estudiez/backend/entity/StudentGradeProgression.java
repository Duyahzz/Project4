package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "StudentGradeProgressions")
public class StudentGradeProgression {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer progressionId;

    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;

    @Column(nullable = false)
    private Integer schoolYearId;

    @Column(nullable = true)
    private Integer previousGrade;

    @Column(nullable = false)
    private Integer newGrade;

    @Column(length = 100)
    private String reason; // e.g., "YEAR_END_PROMOTION", "MANUAL_ASSIGNMENT"

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime progressedAt;
}
