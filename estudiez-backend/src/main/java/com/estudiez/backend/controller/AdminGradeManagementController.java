package com.estudiez.backend.controller;

import com.estudiez.backend.dto.BatchAssignGradeRequest;
import com.estudiez.backend.dto.BatchPromotionRequest;
import com.estudiez.backend.entity.Student;
import com.estudiez.backend.service.AdminGradeManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/admin/grade-management")
@Tag(name = "Admin Grade Management")
public class AdminGradeManagementController {

    private final AdminGradeManagementService adminGradeService;

    @PostMapping("/promote-all-for-year")
    @Operation(summary = "Promote all active students (except grade 12) to next grade at year-end")
    public ResponseEntity<String> promoteAllStudentsForNewYear(
            @RequestParam Integer schoolYearId) {
        adminGradeService.promoteAllStudentsForNewYear(schoolYearId);
        return ResponseEntity.ok("All students promoted successfully for school year: " + schoolYearId);
    }

    @PostMapping("/batch-promote")
    @Operation(summary = "Batch promote students with class mappings")
    public ResponseEntity<String> batchPromoteAndGraduate(@RequestBody BatchPromotionRequest request) {
        adminGradeService.batchPromoteAndGraduate(request);
        return ResponseEntity.ok("Batch promotion completed successfully.");
    }

    @PostMapping("/batch-assign-grade")
    @Operation(summary = "Batch assign grade and class to new students")
    public ResponseEntity<String> batchAssignGradeAndClass(@RequestBody BatchAssignGradeRequest request) {
        adminGradeService.batchAssignGradeAndClass(request);
        return ResponseEntity.ok("Batch grade assignment completed successfully.");
    }

    @PostMapping("/create-new-student-without-grade")
    @Operation(summary = "Create a new student without initial grade assignment")
    public ResponseEntity<Student> createNewStudentWithoutGrade(@RequestBody Student student) {
        Student created = adminGradeService.createNewStudentWithoutGrade(student);
        return ResponseEntity.ok(created);
    }

    @PutMapping("/assign-grade/{studentId}")
    @Operation(summary = "Assign initial grade to a new student")
    public ResponseEntity<Student> assignGradeToNewStudent(
            @PathVariable UUID studentId,
            @RequestParam Integer gradeLevel,
            @RequestParam Integer schoolYearId) {
        Student updated = adminGradeService.assignGradeToNewStudent(studentId, gradeLevel, schoolYearId);
        return ResponseEntity.ok(updated);
    }

    @PutMapping("/mark-as-graduated/{studentId}")
    @Operation(summary = "Mark a grade 12 student as graduated/inactive")
    public ResponseEntity<Student> markStudentAsGraduated(@PathVariable UUID studentId) {
        Student graduated = adminGradeService.markStudentAsGraduated(studentId);
        return ResponseEntity.ok(graduated);
    }

    @GetMapping("/students-by-grade/{grade}")
    @Operation(summary = "Get all students of a specific grade")
    public ResponseEntity<List<Student>> getStudentsByGrade(
            @PathVariable Integer grade,
            @RequestParam Integer schoolYearId) {
        List<Student> students = adminGradeService.getStudentsByGradeForYear(grade, schoolYearId);
        return ResponseEntity.ok(students);
    }

    @GetMapping("/pending-grade-assignment")
    @Operation(summary = "Get all students awaiting grade assignment")
    public ResponseEntity<List<Student>> getStudentsAwaitingGradeAssignment() {
        List<Student> students = adminGradeService.getStudentsAwaitingGradeAssignment();
        return ResponseEntity.ok(students);
    }

    @GetMapping("/grade-12-ready-for-graduation")
    @Operation(summary = "Get all grade 12 students ready for graduation")
    public ResponseEntity<List<Student>> getGrade12StudentsReadyForGraduation() {
        List<Student> students = adminGradeService.getGrade12StudentsReadyForGraduation();
        return ResponseEntity.ok(students);
    }
}
