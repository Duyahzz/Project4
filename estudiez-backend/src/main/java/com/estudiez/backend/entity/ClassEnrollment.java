package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "ClassEnrollments")
public class ClassEnrollment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer enrollmentId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
    @Column(nullable = false)
    private LocalDate enrolledAt;
    private LocalDate leftAt;
    @Column(nullable = false, length = 30)
    private String status = "ACTIVE";
}

