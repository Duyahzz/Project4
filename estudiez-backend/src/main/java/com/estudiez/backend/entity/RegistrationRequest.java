package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "RegistrationRequests")
public class RegistrationRequest {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer requestId;

    @Column(nullable = false, length = 150)
    private String fullName;

    @Column(nullable = false, length = 150)
    private String email;

    @Column(length = 30)
    private String phone;

    @Column(nullable = false, length = 30)
    private String roleRequested;

    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String message;

    @Column(nullable = false, length = 30)
    private String status = "PENDING";

    @Column(columnDefinition = "uniqueidentifier")
    private UUID reviewedBy;

    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String reviewNotes;

    private LocalDateTime reviewedAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

