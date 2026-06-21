package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "NewsPosts")
public class NewsPost {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer newsPostId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID authorUserId;
    @Column(nullable = false, length = 50)
    private String category = "GENERAL";
    @Column(nullable = false, length = 255)
    private String title;
    @Column(nullable = false, unique = true, length = 255)
    private String slug;
    @Column(nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String content;
    @Column(length = 500)
    private String coverImageUrl;
    @Column(nullable = false, length = 30)
    private String status = "DRAFT";
    private LocalDateTime publishedAt;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}

