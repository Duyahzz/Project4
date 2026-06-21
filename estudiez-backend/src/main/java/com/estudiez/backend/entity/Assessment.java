package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Assessments")
public class Assessment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer assessmentId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false)
    private Integer subjectId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID teacherId;
    @Column(nullable = false)
    private Integer semesterId;
    @Column(nullable = false)
    private Integer assessmentTypeId;
    @Column(nullable = false, length = 255)
    private String title;
    @Column(nullable = false)
    private LocalDate assessmentDate;
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal maxScore = BigDecimal.TEN;
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal weight = BigDecimal.ONE;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String description;
    @Column(nullable = false, length = 30)
    private String status = "SCHEDULED";
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

