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
    @Column(name = "progressionId")
    private Integer progressionId;
 
    @Column(name = "studentId", nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
 
    @Column(name = "schoolYearId", nullable = false)
    private Integer schoolYearId;
 
    @Column(name = "previousGrade", nullable = true)
    private Integer previousGrade;
 
    @Column(name = "newGrade", nullable = false)
    private Integer newGrade;
 
    @Column(name = "reason", length = 100)
    private String reason; // e.g., "YEAR_END_PROMOTION", "MANUAL_ASSIGNMENT"
 
    @CreationTimestamp
    @Column(name = "progressedAt", nullable = false, updatable = false)
    private LocalDateTime progressedAt;
}
