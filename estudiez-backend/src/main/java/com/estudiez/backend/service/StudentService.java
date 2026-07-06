package com.estudiez.backend.service;

import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentGradeProgression;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.StudentGradeProgressionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepo;
    private final StudentGradeProgressionRepository progressionRepo;

    public List<Student> findAll() { return studentRepo.findAll(); }

    public Student findById(UUID id) {
        return studentRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Student", id));
    }

    public Student findByCode(String code) {
        return studentRepo.findByStudentCode(code)
            .orElseThrow(() -> new ResourceNotFoundException("Student not found with code: " + code));
    }

    public List<Student> findByStatus(String status) { return studentRepo.findByStatus(status); }

    public Student create(Student student) { return studentRepo.save(student); }

    public Student update(UUID id, Student updated) {
        Student student = findById(id);
        student.setDateOfBirth(updated.getDateOfBirth());
        student.setGender(updated.getGender());
        student.setAddress(updated.getAddress());
        student.setStatus(updated.getStatus());
        return studentRepo.save(student);
    }

    public void delete(UUID id) {
        if (!studentRepo.existsById(id)) throw new ResourceNotFoundException("Student", id);
        studentRepo.deleteById(id);
    }

    /**
     * Assign initial grade to a new student (typically grade 10)
     */
    public Student assignInitialGrade(UUID studentId, Integer initialGrade) {
        Student student = findById(studentId);
        student.setCurrentGrade(initialGrade);
        student.setStatus("ACTIVE");
        return studentRepo.save(student);
    }

    /**
     * Promote student to the next grade at year-end
     * Grade 10 -> 11, Grade 11 -> 12
     * Grade 12 students will need admin approval to mark as GRADUATED/INACTIVE
     */
    @Transactional
    public StudentGradeProgression promoteStudentToNextGrade(UUID studentId, Integer schoolYearId) {
        Student student = findById(studentId);
        
        if (student.getCurrentGrade() == null) {
            throw new IllegalArgumentException("Student must have a current grade to be promoted");
        }
        
        Integer currentGrade = student.getCurrentGrade();
        if (currentGrade >= 12) {
            throw new IllegalArgumentException("Grade 12 students cannot be automatically promoted. " +
                    "Admin must explicitly mark them as GRADUATED or INACTIVE.");
        }
        
        Integer newGrade = currentGrade + 1;
        student.setCurrentGrade(newGrade);
        studentRepo.save(student);
        
        // Record the progression history
        StudentGradeProgression progression = StudentGradeProgression.builder()
                .studentId(studentId)
                .schoolYearId(schoolYearId)
                .previousGrade(currentGrade)
                .newGrade(newGrade)
                .reason("YEAR_END_PROMOTION")
                .build();
        
        return progressionRepo.save(progression);
    }

    /**
     * Mark a grade 12 student as GRADUATED or INACTIVE
     * Requires explicit admin action
     */
    @Transactional
    public Student markStudentAsInactive(UUID studentId, String reason) {
        Student student = findById(studentId);
        
        if (student.getCurrentGrade() != 12) {
            throw new IllegalArgumentException("Only grade 12 students can be marked as inactive/graduated");
        }
        
        student.setStatus("INACTIVE");
        return studentRepo.save(student);
    }

    /**
     * Get all students with a specific grade
     */
    public List<Student> findByGrade(Integer grade) {
        return studentRepo.findAll().stream()
                .filter(s -> s.getCurrentGrade() != null && s.getCurrentGrade().equals(grade))
                .toList();
    }

    /**
     * Get all active students by grade
     */
    public List<Student> findActiveByGrade(Integer grade) {
        return studentRepo.findAll().stream()
                .filter(s -> "ACTIVE".equals(s.getStatus()) && 
                           s.getCurrentGrade() != null && 
                           s.getCurrentGrade().equals(grade))
                .toList();
    }

    /**
     * Get promotion history for a student
     */
    public List<StudentGradeProgression> getProgressionHistory(UUID studentId) {
        return progressionRepo.findByStudentId(studentId);
    }
}
