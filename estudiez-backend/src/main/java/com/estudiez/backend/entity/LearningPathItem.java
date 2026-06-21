package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "LearningPathItems")
public class LearningPathItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer learningPathItemId;
    @Column(nullable = false)
    private Integer learningPathId;
    private Integer skillAreaId;
    private Integer resourceId;
    @Column(nullable = false, length = 255)
    private String title;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String description;
    @Column(nullable = false)
    private Integer priority = 3;
    private LocalDate dueDate;
    @Column(nullable = false, length = 30)
    private String status = "TODO";
    private LocalDateTime completedAt;
}

