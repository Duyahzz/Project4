package com.estudiez.backend.service;

import com.estudiez.backend.entity.Assessment;
import com.estudiez.backend.entity.StudentMark;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.AssessmentRepository;
import com.estudiez.backend.repository.StudentMarkRepository;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.ParentRepository;
import com.estudiez.backend.repository.StudentParentLinkRepository;
import com.estudiez.backend.repository.NotificationRepository;
import com.estudiez.backend.repository.UserRepository;
import com.estudiez.backend.repository.SubjectRepository;
import com.estudiez.backend.repository.TeacherRepository;
import com.estudiez.backend.entity.Teacher;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AssessmentService {

    private final AssessmentRepository assessmentRepo;
    private final StudentMarkRepository studentMarkRepo;
    private final StudentRepository studentRepo;
    private final ParentRepository parentRepo;
    private final StudentParentLinkRepository studentParentLinkRepo;
    private final NotificationRepository notificationRepo;
    private final UserRepository userRepo;
    private final SubjectRepository subjectRepo;
    private final TeacherRepository teacherRepo;

    public List<Assessment> findAll() { return assessmentRepo.findAll(); }

    public Assessment findById(Integer id) {
        return assessmentRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Assessment", id));
    }

    public List<Assessment> findByClass(Integer classId) { return assessmentRepo.findByClassId(classId); }
    public List<Assessment> findByTeacher(UUID teacherId) { return assessmentRepo.findByTeacherId(teacherId); }

    public Assessment create(Assessment assessment) { return assessmentRepo.save(assessment); }

    public Assessment update(Integer id, Assessment updated) {
        Assessment assessment = findById(id);
        assessment.setTitle(updated.getTitle());
        assessment.setAssessmentDate(updated.getAssessmentDate());
        assessment.setMaxScore(updated.getMaxScore());
        assessment.setWeight(updated.getWeight());
        assessment.setDescription(updated.getDescription());
        return assessmentRepo.save(assessment);
    }

    public void delete(Integer id) {
        if (!assessmentRepo.existsById(id)) throw new ResourceNotFoundException("Assessment", id);
        assessmentRepo.deleteById(id);
    }

    // Student Marks
    public List<StudentMark> findMarksByAssessment(Integer assessmentId) {
        return studentMarkRepo.findByAssessmentId(assessmentId);
    }

    public List<StudentMark> findMarksByStudent(UUID studentId) {
        return studentMarkRepo.findByStudentId(studentId);
    }

    public StudentMark saveMark(StudentMark mark) {
        Optional<StudentMark> existing = studentMarkRepo.findByAssessmentIdAndStudentId(mark.getAssessmentId(), mark.getStudentId());
        
        if (mark.getGradedBy() == null) {
            assessmentRepo.findById(mark.getAssessmentId()).ifPresent(assessment -> {
                mark.setGradedBy(assessment.getTeacherId());
            });
        }
        if (mark.getGradedBy() == null) {
            mark.setGradedBy(UUID.fromString("00000000-0000-0000-0000-000000000000"));
        }

        StudentMark saved;
        if (existing.isPresent()) {
            StudentMark em = existing.get();
            em.setScore(mark.getScore());
            em.setTeacherComment(mark.getTeacherComment());
            em.setRemark(mark.getRemark());
            em.setGradedBy(mark.getGradedBy());
            saved = studentMarkRepo.save(em);
        } else {
            saved = studentMarkRepo.save(mark);
        }

        createMarkNotifications(saved);
        return saved;
    }

    private void createMarkNotifications(StudentMark mark) {
        try {
            studentRepo.findById(mark.getStudentId()).ifPresent(student -> {
                userRepo.findById(student.getUserId()).ifPresent(studentUser -> {
                    assessmentRepo.findById(mark.getAssessmentId()).ifPresent(assessment -> {
                        String subjectName = "";
                        if (assessment.getSubjectId() != null) {
                            subjectName = subjectRepo.findById(assessment.getSubjectId())
                                .map(sub -> sub.getName())
                                .orElse("Môn học");
                        }

                        // Notification for Student
                        String studentEmail = studentUser.getEmail();
                        if (studentEmail == null || studentEmail.trim().isEmpty()) {
                            studentEmail = studentUser.getUsername().toLowerCase() + "@estudiez.edu.vn";
                        }
                        
                        UUID senderUserUuid = student.getUserId();
                        if (mark.getGradedBy() != null) {
                            Optional<Teacher> teacherOpt = teacherRepo.findById(mark.getGradedBy());
                            if (teacherOpt.isPresent()) {
                                senderUserUuid = teacherOpt.get().getUserId();
                            }
                        }

                        com.estudiez.backend.entity.Notification studentNotif = com.estudiez.backend.entity.Notification.builder()
                            .senderUserId(senderUserUuid)
                            .title("Điểm số mới / New Assessment Score")
                            .content("Bạn có điểm số mới môn " + subjectName + " (Bài kiểm tra: " + assessment.getTitle() + "): " + mark.getScore() + " điểm.")
                            .category("MARK")
                            .targetType("STUDENT")
                            .targetId(studentEmail)
                            .build();
                        notificationRepo.save(studentNotif);

                        // Find parents and notify them
                        final String finalSubjectName = subjectName;
                        final UUID finalSenderUserUuid = senderUserUuid;
                        studentParentLinkRepo.findByIdStudentId(mark.getStudentId()).forEach(link -> {
                            parentRepo.findById(link.getId().getParentId()).ifPresent(parent -> {
                                userRepo.findById(parent.getUserId()).ifPresent(parentUser -> {
                                    com.estudiez.backend.entity.Notification parentNotif = com.estudiez.backend.entity.Notification.builder()
                                        .senderUserId(finalSenderUserUuid)
                                        .title("Điểm số mới của con / New Assessment Score")
                                        .content("Con của bạn (" + studentUser.getFullName() + ") có điểm số mới môn " + finalSubjectName + " (Bài kiểm tra: " + assessment.getTitle() + "): " + mark.getScore() + " điểm.")
                                        .category("MARK")
                                        .targetType("PARENT")
                                        .targetId(parentUser.getEmail())
                                        .build();
                                    notificationRepo.save(parentNotif);
                                });
                            });
                        });
                    });
                });
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
