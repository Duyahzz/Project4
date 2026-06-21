package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Teachers")
public class Teacher {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    @Column(columnDefinition = "uniqueidentifier")
    private UUID teacherId;

    @Column(nullable = false, unique = true, columnDefinition = "uniqueidentifier")
    private UUID userId;

    @Column(nullable = false, unique = true, length = 50)
    private String employeeCode;

    @Column(nullable = false)
    private Integer subjectId;

    @Column(length = 150)
    private String qualification;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

