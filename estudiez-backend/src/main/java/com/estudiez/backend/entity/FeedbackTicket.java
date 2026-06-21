package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "FeedbackTickets")
public class FeedbackTicket {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer feedbackTicketId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID senderUserId;
    @Column(columnDefinition = "uniqueidentifier")
    private UUID relatedStudentId;
    @Column(nullable = false, length = 50)
    private String category;
    @Column(nullable = false, length = 255)
    private String subject;
    @Column(nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String content;
    @Column(nullable = false, length = 30)
    private String status = "OPEN";
    @Column(columnDefinition = "uniqueidentifier")
    private UUID handledBy;
    private LocalDateTime handledAt;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String adminResponse;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

