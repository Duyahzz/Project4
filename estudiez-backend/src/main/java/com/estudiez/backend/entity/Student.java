package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Students")
public class Student {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    @Column(columnDefinition = "uniqueidentifier")
    private UUID studentId;

    @Column(nullable = false, unique = true, columnDefinition = "uniqueidentifier")
    private UUID userId;

    @Column(nullable = false, unique = true, length = 50)
    private String studentCode;

    private LocalDate dateOfBirth;

    @Column(length = 20)
    private String gender;

    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String address;

    @Column(nullable = false)
    private LocalDate admissionDate;

    @Column(nullable = false, length = 30)
    private String status = "ACTIVE";

    @Column()
    private Integer currentGrade;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

