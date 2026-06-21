package com.estudiez.backend.service;

import com.estudiez.backend.entity.Parent;
import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentParentLink;
import com.estudiez.backend.entity.User;
import com.estudiez.backend.entity.embeddable.StudentParentLinkId;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.ParentRepository;
import com.estudiez.backend.repository.StudentParentLinkRepository;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ParentService {

    private final ParentRepository parentRepo;
    private final StudentParentLinkRepository linkRepo;
    private final StudentRepository studentRepo;
    private final UserRepository userRepo;

    public List<Parent> findAll() { return parentRepo.findAll(); }

    public Parent findById(UUID id) {
        return parentRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Parent", id));
    }

    public Parent findByUserId(UUID userId) {
        return parentRepo.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Parent not found for userId: " + userId));
    }

    public Parent create(Parent parent) { return parentRepo.save(parent); }

    public Parent update(UUID id, Parent updated) {
        Parent parent = findById(id);
        parent.setOccupation(updated.getOccupation());
        parent.setAddress(updated.getAddress());
        return parentRepo.save(parent);
    }

    public void delete(UUID id) {
        if (!parentRepo.existsById(id)) throw new ResourceNotFoundException("Parent", id);
        parentRepo.deleteById(id);
    }

    // ── Relationship queries ──────────────────────────────────────────────────

    /**
     * Returns all students linked to a given parent.
     */
    public List<Student> findStudentsByParentId(UUID parentId) {
        if (!parentRepo.existsById(parentId)) throw new ResourceNotFoundException("Parent", parentId);
        return linkRepo.findByIdParentId(parentId).stream()
                .map(link -> studentRepo.findById(link.getId().getStudentId())
                        .orElseThrow(() -> new ResourceNotFoundException("Student", link.getId().getStudentId())))
                .toList();
    }

    /**
     * Returns all parents linked to a given student.
     */
    public List<Parent> findParentsByStudentId(UUID studentId) {
        if (!studentRepo.existsById(studentId)) throw new ResourceNotFoundException("Student", studentId);
        return linkRepo.findByIdStudentId(studentId).stream()
                .map(link -> parentRepo.findById(link.getId().getParentId())
                        .orElseThrow(() -> new ResourceNotFoundException("Parent", link.getId().getParentId())))
                .toList();
    }

    /**
     * Returns all StudentParentLink records for a student (includes relationship metadata).
     */
    public List<StudentParentLink> findLinksByStudentId(UUID studentId) {
        if (!studentRepo.existsById(studentId)) throw new ResourceNotFoundException("Student", studentId);
        return linkRepo.findByIdStudentId(studentId);
    }

    /**
     * Returns all StudentParentLink records for a parent (includes relationship metadata).
     */
    public List<StudentParentLink> findLinksByParentId(UUID parentId) {
        if (!parentRepo.existsById(parentId)) throw new ResourceNotFoundException("Parent", parentId);
        return linkRepo.findByIdParentId(parentId);
    }

    /**
     * Returns all StudentParentLink records across all parents.
     */
    public List<StudentParentLink> findAllLinks() {
        return linkRepo.findAll();
    }

    // ── Link management ───────────────────────────────────────────────────────

    /**
     * Links a parent to a student identified by the student's account email.
     * This is the primary entry point for the "link by child email" feature.
     */
    @Transactional
    public StudentParentLink linkStudentByEmail(UUID parentId, String childEmail,
                                                String relationship, Boolean isPrimaryContact) {
        // 1. Verify parent exists
        if (!parentRepo.existsById(parentId)) throw new ResourceNotFoundException("Parent", parentId);

        // 2. Look up the user by email
        User childUser = userRepo.findByEmail(childEmail)
                .orElseThrow(() -> new ResourceNotFoundException("No user found with email: " + childEmail));

        // 3. Get the student record for that user
        Student student = studentRepo.findByUserId(childUser.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No student profile found for email: " + childEmail));

        return createLink(parentId, student.getStudentId(), relationship, isPrimaryContact);
    }

    /**
     * Links a parent to a student directly by their IDs.
     */
    @Transactional
    public StudentParentLink linkStudentById(UUID parentId, UUID studentId,
                                             String relationship, Boolean isPrimaryContact) {
        if (!parentRepo.existsById(parentId)) throw new ResourceNotFoundException("Parent", parentId);
        if (!studentRepo.existsById(studentId)) throw new ResourceNotFoundException("Student", studentId);
        return createLink(parentId, studentId, relationship, isPrimaryContact);
    }

    /**
     * Removes the link between a parent and a student.
     */
    @Transactional
    public void unlinkStudent(UUID parentId, UUID studentId) {
        StudentParentLinkId linkId = new StudentParentLinkId(studentId, parentId);
        if (!linkRepo.existsById(linkId)) {
            throw new ResourceNotFoundException(
                    "No link found between parent " + parentId + " and student " + studentId);
        }
        linkRepo.deleteById(linkId);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private StudentParentLink createLink(UUID parentId, UUID studentId,
                                         String relationship, Boolean isPrimaryContact) {
        StudentParentLinkId linkId = new StudentParentLinkId(studentId, parentId);
        if (linkRepo.existsById(linkId)) {
            // Update existing link instead of duplicating
            StudentParentLink existing = linkRepo.findById(linkId).get();
            existing.setRelationship(relationship != null ? relationship : existing.getRelationship());
            if (isPrimaryContact != null) existing.setIsPrimaryContact(isPrimaryContact);
            return linkRepo.save(existing);
        }
        StudentParentLink link = StudentParentLink.builder()
                .id(linkId)
                .relationship(relationship != null ? relationship : "Parent")
                .isPrimaryContact(isPrimaryContact != null ? isPrimaryContact : false)
                .build();
        return linkRepo.save(link);
    }
}

