package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "Users")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    @Column(columnDefinition = "uniqueidentifier")
    private UUID userId;

    @Column(nullable = false)
    private Integer roleId;

    @Column(nullable = false, unique = true, length = 80)
    private String username;

    @Column(nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "PlainPassword", length = 255)
    private String plainPassword;

    @Column(nullable = false, length = 150)
    private String fullName;

    @Column(length = 150)
    private String email;

    @Column(length = 30)
    private String phone;

    @Column(length = 500)
    private String avatarUrl;

    @Column(nullable = false)
    private Boolean isActive = true;

    private LocalDateTime lastLoginAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}

