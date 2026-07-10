package com.estudiez.backend.service;

import com.estudiez.backend.entity.AttendanceRecord;
import com.estudiez.backend.entity.LessonSession;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.AttendanceRecordRepository;
import com.estudiez.backend.repository.LessonSessionRepository;
import com.estudiez.backend.repository.TeacherRepository;
import com.estudiez.backend.repository.StudentRepository;
import com.estudiez.backend.repository.ParentRepository;
import com.estudiez.backend.repository.StudentParentLinkRepository;
import com.estudiez.backend.repository.NotificationRepository;
import com.estudiez.backend.repository.UserRepository;
import com.estudiez.backend.repository.SubjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LessonSessionService {

    private final LessonSessionRepository lessonSessionRepo;
    private final AttendanceRecordRepository attendanceRepo;
    private final TeacherRepository teacherRepo;
    private final StudentRepository studentRepo;
    private final ParentRepository parentRepo;
    private final StudentParentLinkRepository studentParentLinkRepo;
    private final NotificationRepository notificationRepo;
    private final UserRepository userRepo;
    private final SubjectRepository subjectRepo;

    public List<LessonSession> findAll() { return lessonSessionRepo.findAll(); }

    public LessonSession findById(Integer id) {
        return lessonSessionRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("LessonSession", id));
    }

    public List<LessonSession> findByClass(Integer classId) { return lessonSessionRepo.findByClassId(classId); }
    public List<LessonSession> findByTeacher(UUID teacherId) { return lessonSessionRepo.findByTeacherId(teacherId); }

    public LessonSession create(LessonSession session) { return lessonSessionRepo.save(session); }

    public LessonSession update(Integer id, LessonSession updated) {
        LessonSession session = findById(id);
        session.setTopic(updated.getTopic());
        session.setStatus(updated.getStatus());
        session.setRoom(updated.getRoom());
        return lessonSessionRepo.save(session);
    }

    public void delete(Integer id) {
        if (!lessonSessionRepo.existsById(id)) throw new ResourceNotFoundException("LessonSession", id);
        lessonSessionRepo.deleteById(id);
    }

    // Attendance
    public List<AttendanceRecord> findAttendanceBySession(Integer sessionId) {
        return attendanceRepo.findByLessonSessionId(sessionId);
    }

    public List<AttendanceRecord> findAttendanceByStudent(UUID studentId) {
        return attendanceRepo.findByStudentId(studentId);
    }

    public List<AttendanceRecord> findAllAttendance() {
        return attendanceRepo.findAll();
    }

    public AttendanceRecord saveAttendance(AttendanceRecord record) {
        // If recordedBy is not provided by the client, resolve it from the lesson session's teacher
        if (record.getRecordedBy() == null && record.getLessonSessionId() != null) {
            lessonSessionRepo.findById(record.getLessonSessionId()).ifPresent(session -> {
                if (session.getTeacherId() != null) {
                    teacherRepo.findById(session.getTeacherId()).ifPresent(teacher -> {
                        if (teacher.getUserId() != null) {
                            record.setRecordedBy(teacher.getUserId());
                        }
                    });
                }
            });
        }
        AttendanceRecord saved = attendanceRepo.findByLessonSessionIdAndStudentId(record.getLessonSessionId(), record.getStudentId())
            .map(existing -> {
                existing.setStatus(record.getStatus());
                existing.setNote(record.getNote());
                if (record.getRecordedBy() != null) existing.setRecordedBy(record.getRecordedBy());
                return attendanceRepo.save(existing);
            })
            .orElseGet(() -> attendanceRepo.save(record));

        createAttendanceNotifications(saved);
        return saved;
    }

    private void createAttendanceNotifications(AttendanceRecord record) {
        try {
            studentRepo.findById(record.getStudentId()).ifPresent(student -> {
                userRepo.findById(student.getUserId()).ifPresent(studentUser -> {
                    lessonSessionRepo.findById(record.getLessonSessionId()).ifPresent(session -> {
                        String subjectName = "";
                        if (session.getSubjectId() != null) {
                            subjectName = subjectRepo.findById(session.getSubjectId())
                                .map(sub -> sub.getName())
                                .orElse("Môn học");
                        }
                        
                        String dateStr = session.getSessionDate() != null ? session.getSessionDate().toString() : "";
                        if (dateStr.length() > 10) dateStr = dateStr.substring(0, 10);
                        
                        String statusText = record.getStatus();
                        String statusVi = statusText;
                        if ("PRESENT".equalsIgnoreCase(statusText)) statusVi = "Có mặt";
                        else if ("ABSENT".equalsIgnoreCase(statusText)) statusVi = "Vắng mặt";
                        else if ("LATE".equalsIgnoreCase(statusText)) statusVi = "Đi muộn";
                        else if ("EXCUSED".equalsIgnoreCase(statusText)) statusVi = "Nghỉ có phép";
                        
                        // Notification for Student
                        String studentEmail = studentUser.getEmail();
                        if (studentEmail == null || studentEmail.trim().isEmpty()) {
                            studentEmail = studentUser.getUsername().toLowerCase() + "@estudiez.edu.vn";
                        }
                        com.estudiez.backend.entity.Notification studentNotif = com.estudiez.backend.entity.Notification.builder()
                            .senderUserId(record.getRecordedBy() != null ? record.getRecordedBy() : student.getUserId())
                            .title("Cập nhật điểm danh / Attendance Updated")
                            .content("Bạn đã được điểm danh: " + statusVi + " cho môn " + subjectName + " ngày " + dateStr)
                            .category("ATTENDANCE")
                            .targetType("STUDENT")
                            .targetId(studentEmail)
                            .build();
                        notificationRepo.save(studentNotif);

                        // Find parents and notify them
                        final String finalSubjectName = subjectName;
                        final String finalDateStr = dateStr;
                        final String finalStatusVi = statusVi;
                        
                        studentParentLinkRepo.findByIdStudentId(record.getStudentId()).forEach(link -> {
                            parentRepo.findById(link.getId().getParentId()).ifPresent(parent -> {
                                userRepo.findById(parent.getUserId()).ifPresent(parentUser -> {
                                    com.estudiez.backend.entity.Notification parentNotif = com.estudiez.backend.entity.Notification.builder()
                                        .senderUserId(record.getRecordedBy() != null ? record.getRecordedBy() : parent.getUserId())
                                        .title("Cập nhật điểm danh của con / Attendance Updated")
                                        .content("Con của bạn (" + studentUser.getFullName() + ") đã được điểm danh: " + finalStatusVi + " cho môn " + finalSubjectName + " ngày " + finalDateStr)
                                        .category("ATTENDANCE")
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
