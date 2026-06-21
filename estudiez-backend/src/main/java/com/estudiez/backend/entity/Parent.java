package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Parents")
public class Parent {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    @Column(columnDefinition = "uniqueidentifier")
    private UUID parentId;

    @Column(nullable = false, unique = true, columnDefinition = "uniqueidentifier")
    private UUID userId;

    @Column(length = 120)
    private String occupation;

    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String address;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

