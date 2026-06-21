package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "AiRecommendationRuns")
public class AiRecommendationRun {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer aiRunId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
    private Integer subjectId;
    @Column(nullable = false, length = 50)
    private String sourceType;
    @Column(length = 100)
    private String sourceId;
    @Column(length = 100)
    private String modelName;
    @Column(nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String inputSnapshot;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String outputSummary;
    @Column(precision = 5, scale = 2)
    private BigDecimal confidence;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

