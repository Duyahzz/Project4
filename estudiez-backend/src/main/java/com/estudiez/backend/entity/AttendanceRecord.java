package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "AttendanceRecords")
public class AttendanceRecord {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer attendanceId;
    @Column(nullable = false)
    private Integer lessonSessionId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID studentId;
    @Column(nullable = false, length = 30)
    private String status;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String note;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID recordedBy;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime recordedAt;
}

