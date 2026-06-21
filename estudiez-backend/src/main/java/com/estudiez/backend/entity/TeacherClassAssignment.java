package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "TeacherClassAssignments")
public class TeacherClassAssignment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer assignmentId;
    @Column(nullable = false, columnDefinition = "uniqueidentifier")
    private UUID teacherId;
    @Column(nullable = false)
    private Integer classId;
    @Column(nullable = false)
    private Integer subjectId;
    @Column(nullable = false)
    private Integer schoolYearId;
}

