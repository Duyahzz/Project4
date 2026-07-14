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
    @Column(name = "StudentId", columnDefinition = "uniqueidentifier")
    private UUID studentId;

    @Column(name = "UserId", nullable = false, unique = true, columnDefinition = "uniqueidentifier")
    private UUID userId;

    @Column(name = "StudentCode", nullable = false, unique = true, length = 50)
    private String studentCode;

    @Column(name = "DateOfBirth")
    private LocalDate dateOfBirth;

    @Column(name = "Gender", length = 20)
    private String gender;

    @Column(name = "Address", columnDefinition = "NVARCHAR(MAX)")
    private String address;

    @Column(name = "AdmissionDate", nullable = false)
    private LocalDate admissionDate;

    @Column(name = "Status", nullable = false, length = 30)
    private String status = "ACTIVE";

    @Column(name = "CurrentGrade")
    private Integer currentGrade;

    @CreationTimestamp
    @Column(name = "CreatedAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

