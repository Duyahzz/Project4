package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "AiKnowledgeChunks")
public class AiKnowledgeChunk {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer aiKnowledgeChunkId;
    private Integer resourceId;
    @Column(nullable = false)
    private Integer chunkIndex;
    @Column(nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String content;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String metadata;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

