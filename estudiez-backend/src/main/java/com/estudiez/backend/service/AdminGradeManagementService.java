package com.estudiez.backend.service;

import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentGradeProgression;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.StudentGradeProgressionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminGradeManagementService {

    private final StudentRepository studentRepo;
    private final StudentGradeProgressionRepository progressionRepo;

    /**
     * Process year-end grade promotion for all active students (except grade 12)
     * Typically called at the start of a new school year
     */
    @Transactional
    public void promoteAllStudentsForNewYear(Integer schoolYearId) {
        List<Student> activeStudents = studentRepo.findByStatus("ACTIVE");
        
        for (Student student : activeStudents) {
            if (student.getCurrentGrade() != null && student.getCurrentGrade() < 12) {
                Integer currentGrade = student.getCurrentGrade();
                Integer newGrade = currentGrade + 1;
                
                student.setCurrentGrade(newGrade);
                studentRepo.save(student);
                
                // Record progression
                StudentGradeProgression progression = StudentGradeProgression.builder()
                        .studentId(student.getStudentId())
                        .schoolYearId(schoolYearId)
                        .previousGrade(currentGrade)
                        .newGrade(newGrade)
                        .reason("YEAR_END_PROMOTION")
                        .build();
                progressionRepo.save(progression);
            }
        }
    }

    /**
     * Create enrollment for new students at the beginning of the year
     * New students start with no grade assigned yet (null grade)
     * Admin must assign them to a class and grade after creation
     */
    public Student createNewStudentWithoutGrade(Student student) {
        student.setCurrentGrade(null); // No grade initially
        student.setStatus("PENDING_GRADE_ASSIGNMENT");
        return studentRepo.save(student);
    }

    /**
     * Assign a new student to their first grade (typically grade 10)
     * Only possible if student is in PENDING_GRADE_ASSIGNMENT status
     */
    @Transactional
    public Student assignGradeToNewStudent(UUID studentId, Integer gradeLevel, Integer schoolYearId) {
        Student student = studentRepo.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Student not found"));
        
        if (!"PENDING_GRADE_ASSIGNMENT".equals(student.getStatus())) {
            throw new IllegalStateException("Student must be in PENDING_GRADE_ASSIGNMENT status to assign a grade");
        }
        
        if (gradeLevel < 10 || gradeLevel > 12) {
            throw new IllegalArgumentException("Grade must be between 10 and 12");
        }
        
        student.setCurrentGrade(gradeLevel);
        student.setStatus("ACTIVE");
        studentRepo.save(student);
        
        // Record the initial grade assignment
        StudentGradeProgression progression = StudentGradeProgression.builder()
                .studentId(studentId)
                .schoolYearId(schoolYearId)
                .previousGrade(null)
                .newGrade(gradeLevel)
                .reason("INITIAL_GRADE_ASSIGNMENT")
                .build();
        progressionRepo.save(progression);
        
        return student;
    }

    /**
     * Mark a grade 12 student as graduated/inactive
     * Admin must explicitly approve this action
     */
    @Transactional
    public Student markStudentAsGraduated(UUID studentId) {
        Student student = studentRepo.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Student not found"));
        
        if (student.getCurrentGrade() != 12) {
            throw new IllegalStateException("Only grade 12 students can be marked as graduated");
        }
        
        student.setStatus("GRADUATED");
        return studentRepo.save(student);
    }

    /**
     * Get all students by grade in a specific school year
     */
    public List<Student> getStudentsByGradeForYear(Integer grade, Integer schoolYearId) {
        return studentRepo.findAll().stream()
                .filter(s -> s.getCurrentGrade() != null && s.getCurrentGrade().equals(grade) && "ACTIVE".equals(s.getStatus()))
                .toList();
    }

    /**
     * Get all students awaiting grade assignment
     */
    public List<Student> getStudentsAwaitingGradeAssignment() {
        return studentRepo.findByStatus("PENDING_GRADE_ASSIGNMENT");
    }

    /**
     * Get all grade 12 students ready for graduation (to prompt admin for action)
     */
    public List<Student> getGrade12StudentsReadyForGraduation() {
        return studentRepo.findAll().stream()
                .filter(s -> 12 == s.getCurrentGrade() && "ACTIVE".equals(s.getStatus()))
                .toList();
    }
}
