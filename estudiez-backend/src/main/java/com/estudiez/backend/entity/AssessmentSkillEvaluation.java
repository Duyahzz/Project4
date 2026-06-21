package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "AssessmentSkillEvaluations")
public class AssessmentSkillEvaluation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer evaluationId;
    @Column(nullable = false)
    private Integer studentMarkId;
    @Column(nullable = false)
    private Integer skillAreaId;
    @Column(precision = 5, scale = 2)
    private BigDecimal masteryLevel;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String strengths;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String weaknesses;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String teacherFeedback;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String evidence;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

