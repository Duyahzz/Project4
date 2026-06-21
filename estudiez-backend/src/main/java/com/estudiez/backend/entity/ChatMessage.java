package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "ChatMessages")
public class ChatMessage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer chatMessageId;
    @Column(nullable = false)
    private Integer chatGroupId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID senderUserId;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String messageText;
    @Column(length = 500)
    private String attachmentUrl;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    private LocalDateTime deletedAt;
}

