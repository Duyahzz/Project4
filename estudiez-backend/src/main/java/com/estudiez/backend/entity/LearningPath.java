package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "LearningPaths")
public class LearningPath {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer learningPathId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
    @Column(nullable = false)
    private Integer subjectId;
    private Integer aiRunId;
    @Column(nullable = false, length = 255)
    private String title;
    @Column(nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String goal;
    @Column(nullable = false, length = 30)
    private String status = "ACTIVE";
    @Column(nullable = false)
    private LocalDate startDate;
    private LocalDate targetEndDate;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

