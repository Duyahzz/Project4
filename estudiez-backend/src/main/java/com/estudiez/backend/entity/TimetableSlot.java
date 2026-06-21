package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "TimetableSlots")
public class TimetableSlot {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer timetableSlotId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false)
    private Integer subjectId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID teacherId;
    @Column(nullable = false)
    private Integer semesterId;
    @Column(nullable = false)
    private Integer dayOfWeek;
    @Column(nullable = false)
    private Integer periodNo;
    @Column(nullable = false)
    private LocalTime startTime;
    @Column(nullable = false)
    private LocalTime endTime;
    @Column(length = 50)
    private String room;
    @Column(nullable = false)
    private LocalDate effectiveFrom;
    private LocalDate effectiveTo;
}

