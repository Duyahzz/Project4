package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "StudyResources")
public class StudyResource {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer resourceId;
    @Column(nullable = false)
    private Integer subjectId;
    private Integer classId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID uploadedBy;
    @Column(nullable = false, length = 255)
    private String title;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String description;
    @Column(nullable = false, length = 30)
    private String resourceType;
    @Column(nullable = false, length = 500)
    private String fileUrl;
    @Column(length = 500)
    private String thumbnailUrl;
    @Column(nullable = false, length = 30)
    private String visibility = "CLASS_ONLY";
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

