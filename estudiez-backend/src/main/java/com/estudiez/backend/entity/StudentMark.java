package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "StudentMarks")
public class StudentMark {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer studentMarkId;
    @Column(nullable = false)
    private Integer assessmentId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal score;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String teacherComment;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String remark;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID gradedBy;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime gradedAt;
}

