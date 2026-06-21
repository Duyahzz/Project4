package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "ChatGroups")
public class ChatGroup {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer chatGroupId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false)
    private Integer schoolYearId;
    @Column(nullable = false, length = 30)
    private String groupType;
    @Column(nullable = false, length = 150)
    private String name;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

