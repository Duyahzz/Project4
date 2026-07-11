package com.estudiez.backend.controller;

import com.estudiez.backend.entity.ClassEnrollment;
import com.estudiez.backend.entity.SchoolClass;
import com.estudiez.backend.repository.ClassEnrollmentRepository;
import com.estudiez.backend.repository.SchoolClassRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Tag(name = "ClassEnrollments")
@RestController
@RequestMapping("/api/enrollments")
@RequiredArgsConstructor
public class ClassEnrollmentController {
    private final ClassEnrollmentRepository repo;
    private final SchoolClassRepository classRepo;

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

    /**
     * Enroll a student into a class, enforcing capacity limits.
     * Body: { classId: number (as string), studentId: UUID string }
     */
    @PostMapping("/enroll")
    @Transactional
    @Operation(summary = "Enroll a student into a class (respects student limit)")
    public ResponseEntity<?> enroll(@RequestBody Map<String, String> body) {
        Integer classId;
        UUID studentId;
        try {
            classId = Integer.parseInt(body.get("classId"));
            studentId = UUID.fromString(body.get("studentId"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid classId or studentId"));
        }

        SchoolClass schoolClass = classRepo.findById(classId).orElse(null);
        if (schoolClass == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Class not found"));
        }

        int limit = schoolClass.getStudentLimit() != null ? schoolClass.getStudentLimit() : 40;
        long current = repo.countByClassIdAndStatus(classId, "ACTIVE");
        if (current >= limit) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Class " + schoolClass.getName() + " is at full capacity (" + limit + " students)"
            ));
        }

        // Close any existing active enrollment for this student
        repo.findByStudentIdAndStatus(studentId, "ACTIVE").forEach(e -> {
            e.setStatus("COMPLETED");
            e.setLeftAt(LocalDate.now());
            repo.save(e);
        });

        ClassEnrollment enrollment = ClassEnrollment.builder()
                .classId(classId)
                .studentId(studentId)
                .enrolledAt(LocalDate.now())
                .status("ACTIVE")
                .build();
        repo.save(enrollment);
        return ResponseEntity.ok(Map.of("message", "Enrolled successfully"));
    }

    /**
     * Remove (soft-delete) a student's active enrollment from a class.
     * Body: { classId: number (as string), studentId: UUID string }
     */
    @PostMapping("/remove")
    @Transactional
    @Operation(summary = "Remove a student from a class")
    public ResponseEntity<?> remove(@RequestBody Map<String, String> body) {
        Integer classId;
        UUID studentId;
        try {
            classId = Integer.parseInt(body.get("classId"));
            studentId = UUID.fromString(body.get("studentId"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid classId or studentId"));
        }

        List<ClassEnrollment> active = repo.findByStudentIdAndStatus(studentId, "ACTIVE").stream()
                .filter(e -> e.getClassId().equals(classId))
                .toList();
        if (active.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "No active enrollment found for this student in this class"));
        }
        active.forEach(e -> {
            e.setStatus("DROPPED");
            e.setLeftAt(LocalDate.now());
            repo.save(e);
        });
        return ResponseEntity.ok(Map.of("message", "Removed from class successfully"));
    }
}
