package com.estudiez.backend.controller;

import com.estudiez.backend.entity.Parent;
import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentParentLink;
import com.estudiez.backend.entity.StudentGradeProgression;
import com.estudiez.backend.service.ParentService;
import com.estudiez.backend.service.StudentService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;
    private final ParentService parentService;

    @GetMapping
    public List<Student> getAll(@RequestParam(required = false) String status) {
        return status != null ? studentService.findByStatus(status) : studentService.findAll();
    }

    @GetMapping("/{id}")
    public Student getById(@PathVariable UUID id) { return studentService.findById(id); }

    @GetMapping("/code/{code}")
    public Student getByCode(@PathVariable String code) { return studentService.findByCode(code); }

    @PostMapping
    public ResponseEntity<Student> create(@RequestBody Student student) {
        return ResponseEntity.status(HttpStatus.CREATED).body(studentService.create(student));
    }

    @PutMapping("/{id}")
    public Student update(@PathVariable UUID id, @RequestBody Student student) {
        return studentService.update(id, student);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        studentService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/by-grade/{grade}")
    @Operation(summary = "Get all students with a specific grade")
    public List<Student> getByGrade(@PathVariable Integer grade) {
        return studentService.findByGrade(grade);
    }

    @GetMapping("/by-grade-active/{grade}")
    @Operation(summary = "Get all active students with a specific grade")
    public List<Student> getActiveByGrade(@PathVariable Integer grade) {
        return studentService.findActiveByGrade(grade);
    }

    @GetMapping("/{id}/grade-history")
    @Operation(summary = "Get grade progression history for a student")
    public List<StudentGradeProgression> getGradeHistory(@PathVariable UUID id) {
        return studentService.getProgressionHistory(id);
    }

    // ── Student → Parents ─────────────────────────────────────────────────────

    @Operation(summary = "Get parents linked to a student")
    @GetMapping("/{id}/parents")
    public List<Parent> getParents(@PathVariable UUID id) {
        return parentService.findParentsByStudentId(id);
    }

    @Operation(summary = "Get parent–student links for a student",
               description = "Returns link records including relationship type and isPrimaryContact.")
    @GetMapping("/{id}/parent-links")
    public List<StudentParentLink> getParentLinks(@PathVariable UUID id) {
        return parentService.findLinksByStudentId(id);
    }
}

