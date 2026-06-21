package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "LessonSessions")
public class LessonSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer lessonSessionId;
    private Integer timetableSlotId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false)
    private Integer subjectId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID teacherId;
    @Column(nullable = false)
    private LocalDate sessionDate;
    @Column(nullable = false)
    private Integer periodNo;
    @Column(length = 50)
    private String room;
    @Column(length = 255)
    private String topic;
    @Column(nullable = false, length = 30)
    private String status = "SCHEDULED";
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

