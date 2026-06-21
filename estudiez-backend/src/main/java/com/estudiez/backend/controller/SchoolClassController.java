package com.estudiez.backend.controller;

import com.estudiez.backend.entity.SchoolClass;
import com.estudiez.backend.service.SchoolClassService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
public class SchoolClassController {

    private final SchoolClassService classService;

    @GetMapping
    public List<SchoolClass> getAll(@RequestParam(required = false) Integer schoolYearId) {
        return schoolYearId != null ? classService.findBySchoolYear(schoolYearId) : classService.findAll();
    }

    @GetMapping("/{id}")
    public SchoolClass getById(@PathVariable Integer id) { return classService.findById(id); }

    @PostMapping
    public ResponseEntity<SchoolClass> create(@RequestBody SchoolClass schoolClass) {
        return ResponseEntity.status(HttpStatus.CREATED).body(classService.create(schoolClass));
    }

    @PutMapping("/{id}")
    public SchoolClass update(@PathVariable Integer id, @RequestBody SchoolClass schoolClass) {
        return classService.update(id, schoolClass);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        classService.delete(id);
        return ResponseEntity.noContent().build();
    }
}

