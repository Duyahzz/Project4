package com.estudiez.backend.controller;

import com.estudiez.backend.entity.Assessment;
import com.estudiez.backend.entity.StudentMark;
import com.estudiez.backend.service.AssessmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/assessments")
@RequiredArgsConstructor
public class AssessmentController {

    private final AssessmentService assessmentService;

    @GetMapping
    public List<Assessment> getAll(@RequestParam(required = false) Integer classId) {
        return classId != null ? assessmentService.findByClass(classId) : assessmentService.findAll();
    }

    @GetMapping("/{id}")
    public Assessment getById(@PathVariable Integer id) { return assessmentService.findById(id); }

    @GetMapping("/{id}/marks")
    public List<StudentMark> getMarks(@PathVariable Integer id) {
        return assessmentService.findMarksByAssessment(id);
    }

    @GetMapping("/student/{studentId}/marks")
    public List<StudentMark> getMarksByStudent(@PathVariable UUID studentId) {
        return assessmentService.findMarksByStudent(studentId);
    }

    @PostMapping
    public ResponseEntity<Assessment> create(@RequestBody Assessment assessment) {
        return ResponseEntity.status(HttpStatus.CREATED).body(assessmentService.create(assessment));
    }

    @PutMapping("/{id}")
    public Assessment update(@PathVariable Integer id, @RequestBody Assessment assessment) {
        return assessmentService.update(id, assessment);
    }

    @PostMapping("/{id}/marks")
    public ResponseEntity<StudentMark> saveMark(@PathVariable Integer id, @RequestBody StudentMark mark) {
        mark.setAssessmentId(id);
        return ResponseEntity.status(HttpStatus.CREATED).body(assessmentService.saveMark(mark));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        assessmentService.delete(id);
        return ResponseEntity.noContent().build();
    }
}

