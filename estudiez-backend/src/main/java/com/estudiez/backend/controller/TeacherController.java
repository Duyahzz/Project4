package com.estudiez.backend.controller;

import com.estudiez.backend.entity.Teacher;
import com.estudiez.backend.service.TeacherService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/teachers")
@RequiredArgsConstructor
public class TeacherController {

    private final TeacherService teacherService;

    @GetMapping
    public List<Teacher> getAll(@RequestParam(required = false) Integer subjectId) {
        return subjectId != null ? teacherService.findBySubject(subjectId) : teacherService.findAll();
    }

    @GetMapping("/{id}")
    public Teacher getById(@PathVariable UUID id) { return teacherService.findById(id); }

    @PostMapping
    public ResponseEntity<Teacher> create(@RequestBody Teacher teacher) {
        return ResponseEntity.status(HttpStatus.CREATED).body(teacherService.create(teacher));
    }

    @PutMapping("/{id}")
    public Teacher update(@PathVariable UUID id, @RequestBody Teacher teacher) {
        return teacherService.update(id, teacher);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        teacherService.delete(id);
        return ResponseEntity.noContent().build();
    }
}

