package com.estudiez.backend.service;

import com.estudiez.backend.entity.Student;
import com.estudiez.backend.entity.StudentGradeProgression;
import com.estudiez.backend.entity.SchoolClass;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.StudentGradeProgressionRepository;
import com.estudiez.backend.repository.ClassEnrollmentRepository;
import com.estudiez.backend.repository.SchoolClassRepository;
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
    private final ClassEnrollmentRepository classEnrollmentRepo;
    private final SchoolClassRepository classRepo;

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

    /**
     * Batch process year-end promotions, class assignments, and graduations
     */
    @Transactional
    public void batchPromoteAndGraduate(com.estudiez.backend.dto.BatchPromotionRequest request) {
        if (request.getClassMappings() == null || request.getClassMappings().isEmpty()) {
            return;
        }

        // Guard: two source classes must not share the same target class
        java.util.Map<Integer, Integer> targetToSource = new java.util.HashMap<>();
        for (com.estudiez.backend.dto.ClassPromotionMapping mapping : request.getClassMappings()) {
            if (mapping.getTargetClassId() == null) continue;
            Integer prev = targetToSource.put(mapping.getTargetClassId(), mapping.getSourceClassId());
            if (prev != null) {
                SchoolClass dup = classRepo.findById(mapping.getTargetClassId()).orElse(null);
                String dupName = dup != null ? dup.getName() : "#" + mapping.getTargetClassId();
                throw new IllegalArgumentException(
                    "Duplicate target class detected: class '" + dupName
                    + "' is mapped to more than one source class. Each target class can only receive students from one source.");
            }
        }

        // Pre-check target class limits
        java.util.Map<Integer, Integer> targetClassAssignments = new java.util.HashMap<>();
        for (com.estudiez.backend.dto.ClassPromotionMapping mapping : request.getClassMappings()) {
            Integer sourceClassId = mapping.getSourceClassId();
            Integer targetClassId = mapping.getTargetClassId();
            if (sourceClassId == null || targetClassId == null) continue;

            List<com.estudiez.backend.entity.ClassEnrollment> sourceEnrollments = 
                    classEnrollmentRepo.findByClassId(sourceClassId);

            int studentsToAssign = 0;
            for (com.estudiez.backend.entity.ClassEnrollment enrollment : sourceEnrollments) {
                if (!"ACTIVE".equals(enrollment.getStatus())) {
                    continue;
                }
                if (request.getStudentIds() != null && !request.getStudentIds().contains(enrollment.getStudentId())) {
                    continue;
                }
                
                UUID studentId = enrollment.getStudentId();
                Student student = studentRepo.findById(studentId).orElse(null);
                if (student != null && student.getCurrentGrade() != null && student.getCurrentGrade() < 12) {
                    studentsToAssign++;
                }
            }
            if (studentsToAssign > 0) {
                targetClassAssignments.put(targetClassId, targetClassAssignments.getOrDefault(targetClassId, 0) + studentsToAssign);
            }
        }

        for (java.util.Map.Entry<Integer, Integer> entry : targetClassAssignments.entrySet()) {
            Integer targetClassId = entry.getKey();
            Integer countToAssign = entry.getValue();

            SchoolClass targetClass = classRepo.findById(targetClassId)
                    .orElseThrow(() -> new IllegalArgumentException("Class not found: " + targetClassId));
            long currentActive = classEnrollmentRepo.countByClassIdAndStatus(targetClassId, "ACTIVE");
            if (currentActive + countToAssign > targetClass.getStudentLimit()) {
                throw new IllegalStateException("Class " + targetClass.getName() + " cannot accept " + countToAssign + " more student(s) as it would exceed its limit of " + targetClass.getStudentLimit() + ".");
            }
        }

        java.time.LocalDate now = java.time.LocalDate.now();

        for (com.estudiez.backend.dto.ClassPromotionMapping mapping : request.getClassMappings()) {
            Integer sourceClassId = mapping.getSourceClassId();
            Integer targetClassId = mapping.getTargetClassId();

            if (sourceClassId == null) continue;

            // Fetch active enrollments in the source class
            List<com.estudiez.backend.entity.ClassEnrollment> sourceEnrollments = 
                    classEnrollmentRepo.findByClassId(sourceClassId);

            for (com.estudiez.backend.entity.ClassEnrollment enrollment : sourceEnrollments) {
                if (!"ACTIVE".equals(enrollment.getStatus())) {
                    continue;
                }

                // Check if student is selected for promotion/graduation
                if (request.getStudentIds() != null && !request.getStudentIds().contains(enrollment.getStudentId())) {
                    continue;
                }

                // 1. Close current enrollment
                enrollment.setLeftAt(now);
                enrollment.setStatus("COMPLETED");
                classEnrollmentRepo.save(enrollment);

                // Fetch student details
                UUID studentId = enrollment.getStudentId();
                com.estudiez.backend.entity.Student student = studentRepo.findById(studentId)
                        .orElse(null);
                if (student == null) continue;

                Integer currentGrade = student.getCurrentGrade();

                if (currentGrade != null && currentGrade == 12) {
                    // Graduating student
                    student.setStatus("GRADUATED");
                    studentRepo.save(student);

                    // Record progression
                    com.estudiez.backend.entity.StudentGradeProgression progression = 
                            com.estudiez.backend.entity.StudentGradeProgression.builder()
                                    .studentId(studentId)
                                    .schoolYearId(request.getTargetSchoolYearId())
                                    .previousGrade(currentGrade)
                                    .newGrade(12)
                                    .reason("GRADUATION")
                                    .build();
                    progressionRepo.save(progression);
                } else if (currentGrade != null && currentGrade < 12) {
                    // Promoting student
                    Integer newGrade = currentGrade + 1;
                    student.setCurrentGrade(newGrade);
                    studentRepo.save(student);

                    // Record progression
                    com.estudiez.backend.entity.StudentGradeProgression progression = 
                            com.estudiez.backend.entity.StudentGradeProgression.builder()
                                    .studentId(studentId)
                                    .schoolYearId(request.getTargetSchoolYearId())
                                    .previousGrade(currentGrade)
                                    .newGrade(newGrade)
                                    .reason("YEAR_END_PROMOTION")
                                    .build();
                    progressionRepo.save(progression);

                    // If target class is mapped, enroll student in target class
                    if (targetClassId != null) {
                        com.estudiez.backend.entity.ClassEnrollment newEnrollment = 
                                com.estudiez.backend.entity.ClassEnrollment.builder()
                                        .classId(targetClassId)
                                        .studentId(studentId)
                                        .enrolledAt(now)
                                        .status("ACTIVE")
                                        .build();
                        classEnrollmentRepo.save(newEnrollment);
                    }
                }
            }
        }
    }

    /**
     * Batch assign initial grade and class to new students
     */
    @Transactional
    public void batchAssignGradeAndClass(com.estudiez.backend.dto.BatchAssignGradeRequest request) {
        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            return;
        }

        if (request.getTargetClassId() != null) {
            SchoolClass targetClass = classRepo.findById(request.getTargetClassId())
                    .orElseThrow(() -> new IllegalArgumentException("Class not found: " + request.getTargetClassId()));
            long currentActive = classEnrollmentRepo.countByClassIdAndStatus(request.getTargetClassId(), "ACTIVE");
            int studentsToAssign = request.getStudentIds().size();
            if (currentActive + studentsToAssign > targetClass.getStudentLimit()) {
                throw new IllegalStateException("Class " + targetClass.getName() + " cannot accept " + studentsToAssign + " more student(s) as it would exceed its limit of " + targetClass.getStudentLimit() + ".");
            }
        }

        java.time.LocalDate now = java.time.LocalDate.now();

        for (UUID studentId : request.getStudentIds()) {
            com.estudiez.backend.entity.Student student = studentRepo.findById(studentId)
                    .orElseThrow(() -> new IllegalArgumentException("Student not found: " + studentId));

            if (!"PENDING_GRADE_ASSIGNMENT".equals(student.getStatus())) {
                throw new IllegalStateException("Student must be in PENDING_GRADE_ASSIGNMENT status to assign a grade");
            }

            Integer gradeLevel = request.getGradeLevel();
            if (gradeLevel < 10 || gradeLevel > 12) {
                throw new IllegalArgumentException("Grade must be between 10 and 12");
            }

            student.setCurrentGrade(gradeLevel);
            student.setStatus("ACTIVE");
            studentRepo.save(student);

            // Record progression
            com.estudiez.backend.entity.StudentGradeProgression progression = 
                    com.estudiez.backend.entity.StudentGradeProgression.builder()
                            .studentId(studentId)
                            .schoolYearId(request.getSchoolYearId())
                            .previousGrade(null)
                            .newGrade(gradeLevel)
                            .reason("INITIAL_GRADE_ASSIGNMENT")
                            .build();
                    progressionRepo.save(progression);

            // Create active enrollment in selected target class
            if (request.getTargetClassId() != null) {
                com.estudiez.backend.entity.ClassEnrollment enrollment = 
                        com.estudiez.backend.entity.ClassEnrollment.builder()
                                .classId(request.getTargetClassId())
                                .studentId(studentId)
                                .enrolledAt(now)
                                .status("ACTIVE")
                                .build();
                classEnrollmentRepo.save(enrollment);
            }
        }
    }
}
