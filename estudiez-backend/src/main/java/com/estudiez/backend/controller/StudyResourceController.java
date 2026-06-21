package com.estudiez.backend.controller;

import com.estudiez.backend.entity.StudyResource;
import com.estudiez.backend.service.StudyResourceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/resources")
@RequiredArgsConstructor
public class StudyResourceController {

    private final StudyResourceService resourceService;

    @GetMapping
    public List<StudyResource> getAll(
            @RequestParam(required = false) Integer classId,
            @RequestParam(required = false) Integer subjectId) {
        if (classId != null) return resourceService.findByClass(classId);
        if (subjectId != null) return resourceService.findBySubject(subjectId);
        return resourceService.findAll();
    }

    @GetMapping("/{id}")
    public StudyResource getById(@PathVariable Integer id) { return resourceService.findById(id); }

    @PostMapping
    public ResponseEntity<StudyResource> create(@RequestBody StudyResource resource) {
        return ResponseEntity.status(HttpStatus.CREATED).body(resourceService.create(resource));
    }

    @PutMapping("/{id}")
    public StudyResource update(@PathVariable Integer id, @RequestBody StudyResource resource) {
        return resourceService.update(id, resource);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        resourceService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
