package com.estudiez.backend.controller;

import com.estudiez.backend.entity.ClassEnrollment;
import com.estudiez.backend.repository.ClassEnrollmentRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "ClassEnrollments")
@RestController
@RequestMapping("/api/enrollments")
@RequiredArgsConstructor
public class ClassEnrollmentController {
    private final ClassEnrollmentRepository repo;

    @GetMapping
    @Operation(summary = "Get all enrollments")
    public List<ClassEnrollment> getAll() {
        return repo.findAll();
    }

    @GetMapping("/class/{classId}")
    @Operation(summary = "Get enrollments by class")
    public List<ClassEnrollment> getByClass(@PathVariable Integer classId) {
        return repo.findByClassId(classId);
    }

    @GetMapping("/student/{studentId}")
    @Operation(summary = "Get enrollments by student")
    public List<ClassEnrollment> getByStudent(@PathVariable UUID studentId) {
        return repo.findByStudentId(studentId);
    }

    @GetMapping("/student/{studentId}/active")
    @Operation(summary = "Get active enrollment for student")
    public ResponseEntity<ClassEnrollment> getActiveByStudent(@PathVariable UUID studentId) {
        return repo.findByStudentIdAndStatus(studentId, "ACTIVE").stream()
                .findFirst()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
