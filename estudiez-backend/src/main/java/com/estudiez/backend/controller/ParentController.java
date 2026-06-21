package com.estudiez.backend.controller;

import com.estudiez.backend.controller.dto.LinkStudentRequest;
import com.estudiez.backend.entity.Parent;
import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentParentLink;
import com.estudiez.backend.service.ParentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "Parents", description = "Parent profiles and parent–student relationship management")
@RestController
@RequestMapping("/api/parents")
@RequiredArgsConstructor
public class ParentController {

    private final ParentService parentService;

    // ── CRUD ──────────────────────────────────────────────────────────────────

    @Operation(summary = "List all parents")
    @GetMapping
    public List<Parent> getAll() { return parentService.findAll(); }

    @Operation(summary = "Get parent by ID")
    @GetMapping("/{id}")
    public Parent getById(@PathVariable UUID id) { return parentService.findById(id); }

    @Operation(summary = "Get parent by user account ID")
    @GetMapping("/user/{userId}")
    public Parent getByUserId(@PathVariable UUID userId) { return parentService.findByUserId(userId); }

    @Operation(summary = "Create a parent profile")
    @PostMapping
    public ResponseEntity<Parent> create(@RequestBody Parent parent) {
        return ResponseEntity.status(HttpStatus.CREATED).body(parentService.create(parent));
    }

    @Operation(summary = "Update a parent profile")
    @PutMapping("/{id}")
    public Parent update(@PathVariable UUID id, @RequestBody Parent parent) {
        return parentService.update(id, parent);
    }

    @Operation(summary = "Delete a parent profile")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        parentService.delete(id);
        return ResponseEntity.noContent().build();
    }

    // ── Parent → Students ─────────────────────────────────────────────────────

    @Operation(
        summary = "Get all parent–student links",
        description = "Returns all link records across all parents (useful for admin dashboards)."
    )
    @GetMapping("/links")
    public List<StudentParentLink> getAllLinks() {
        return parentService.findAllLinks();
    }

    @Operation(
        summary = "Get students linked to a parent",
        description = "Returns all student profiles that are linked to this parent."
    )
    @GetMapping("/{id}/students")
    public List<Student> getStudents(@PathVariable UUID id) {
        return parentService.findStudentsByParentId(id);
    }

    @Operation(
        summary = "Get parent–student links for a parent",
        description = "Returns link records (includes relationship type and isPrimaryContact flag)."
    )
    @GetMapping("/{id}/links")
    public List<StudentParentLink> getLinks(@PathVariable UUID id) {
        return parentService.findLinksByParentId(id);
    }

    @Operation(
        summary = "Link a parent to a student",
        description = """
            Links a parent to a student. Provide either:
            - `childEmail` — the student's account email address (e.g. bao.pq@school.edu), **or**
            - `studentId` — the student's UUID directly.

            Optional fields: `relationship` (default: "Parent"), `isPrimaryContact` (default: false).
            If the link already exists, it will be updated with the new values.
            """
    )
    @PostMapping("/{id}/students")
    public ResponseEntity<StudentParentLink> linkStudent(
            @PathVariable UUID id,
            @RequestBody LinkStudentRequest request) {

        StudentParentLink link;
        if (request.childEmail() != null && !request.childEmail().isBlank()) {
            link = parentService.linkStudentByEmail(
                    id, request.childEmail(), request.relationship(), request.isPrimaryContact());
        } else if (request.studentId() != null && !request.studentId().isBlank()) {
            link = parentService.linkStudentById(
                    id, UUID.fromString(request.studentId()), request.relationship(), request.isPrimaryContact());
        } else {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(link);
    }

    @Operation(
        summary = "Unlink a parent from a student",
        description = "Removes the parent–student relationship record."
    )
    @DeleteMapping("/{id}/students/{studentId}")
    public ResponseEntity<Void> unlinkStudent(@PathVariable UUID id, @PathVariable UUID studentId) {
        parentService.unlinkStudent(id, studentId);
        return ResponseEntity.noContent().build();
    }
}

