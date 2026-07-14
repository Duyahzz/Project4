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
    @Column(name = "progression_id")
    private Integer progressionId;
 
    @Column(name = "student_id", nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
 
    @Column(name = "school_year_id", nullable = false)
    private Integer schoolYearId;
 
    @Column(name = "previous_grade", nullable = true)
    private Integer previousGrade;
 
    @Column(name = "new_grade", nullable = false)
    private Integer newGrade;
 
    @Column(name = "reason", length = 100)
    private String reason; // e.g., "YEAR_END_PROMOTION", "MANUAL_ASSIGNMENT"
 
    @CreationTimestamp
    @Column(name = "progressed_at", nullable = false, updatable = false)
    private LocalDateTime progressedAt;
}
