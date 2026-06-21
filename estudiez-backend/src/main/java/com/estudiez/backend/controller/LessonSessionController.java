package com.estudiez.backend.controller;

import com.estudiez.backend.entity.AttendanceRecord;
import com.estudiez.backend.entity.LessonSession;
import com.estudiez.backend.service.LessonSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/lessons")
@RequiredArgsConstructor
public class LessonSessionController {

    private final LessonSessionService lessonService;

    @GetMapping
    public List<LessonSession> getAll(@RequestParam(required = false) Integer classId) {
        return classId != null ? lessonService.findByClass(classId) : lessonService.findAll();
    }

    @GetMapping("/{id}")
    public LessonSession getById(@PathVariable Integer id) { return lessonService.findById(id); }

    @GetMapping("/{id}/attendance")
    public List<AttendanceRecord> getAttendance(@PathVariable Integer id) {
        return lessonService.findAttendanceBySession(id);
    }

    @GetMapping("/attendance/student/{studentId}")
    public List<AttendanceRecord> getAttendanceByStudent(@PathVariable UUID studentId) {
        return lessonService.findAttendanceByStudent(studentId);
    }

    @GetMapping("/attendance")
    public List<AttendanceRecord> getAllAttendance() {
        return lessonService.findAllAttendance();
    }

    @PostMapping
    public ResponseEntity<LessonSession> create(@RequestBody LessonSession session) {
        return ResponseEntity.status(HttpStatus.CREATED).body(lessonService.create(session));
    }

    @PutMapping("/{id}")
    public LessonSession update(@PathVariable Integer id, @RequestBody LessonSession session) {
        return lessonService.update(id, session);
    }

    @PostMapping("/{id}/attendance")
    public ResponseEntity<AttendanceRecord> recordAttendance(@PathVariable Integer id,
                                                              @RequestBody AttendanceRecord record) {
        record.setLessonSessionId(id);
        return ResponseEntity.status(HttpStatus.CREATED).body(lessonService.saveAttendance(record));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        lessonService.delete(id);
        return ResponseEntity.noContent().build();
    }
}

