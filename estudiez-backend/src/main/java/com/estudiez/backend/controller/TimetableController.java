package com.estudiez.backend.controller;

import com.estudiez.backend.entity.TimetableSlot;
import com.estudiez.backend.service.TimetableService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/timetable")
@RequiredArgsConstructor
public class TimetableController {

    private final TimetableService timetableService;

    @GetMapping
    public List<TimetableSlot> getAll(
            @RequestParam(required = false) Integer classId,
            @RequestParam(required = false) Integer semesterId) {
        if (classId != null && semesterId != null)
            return timetableService.findByClassAndSemester(classId, semesterId);
        if (classId != null)
            return timetableService.findByClass(classId);
        return timetableService.findAll();
    }

    @GetMapping("/{id}")
    public TimetableSlot getById(@PathVariable Integer id) { return timetableService.findById(id); }

    @PostMapping
    public ResponseEntity<TimetableSlot> create(@RequestBody TimetableSlot slot) {
        return ResponseEntity.status(HttpStatus.CREATED).body(timetableService.create(slot));
    }

    @PutMapping("/{id}")
    public TimetableSlot update(@PathVariable Integer id, @RequestBody TimetableSlot slot) {
        return timetableService.update(id, slot);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        timetableService.delete(id);
        return ResponseEntity.noContent().build();
    }
 
    @PostMapping("/clone-year")
    public ResponseEntity<Integer> cloneTimetableSlots(
            @RequestParam Integer sourceYearId,
            @RequestParam Integer targetYearId) {
        int count = timetableService.cloneTimetableSlots(sourceYearId, targetYearId);
        return ResponseEntity.ok(count);
    }
}
