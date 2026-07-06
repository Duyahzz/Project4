package com.estudiez.backend.service;

import com.estudiez.backend.entity.AttendanceRecord;
import com.estudiez.backend.entity.LessonSession;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.AttendanceRecordRepository;
import com.estudiez.backend.repository.LessonSessionRepository;
import com.estudiez.backend.repository.TeacherRepository;
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
        return attendanceRepo.findByLessonSessionIdAndStudentId(record.getLessonSessionId(), record.getStudentId())
            .map(existing -> {
                existing.setStatus(record.getStatus());
                existing.setNote(record.getNote());
                if (record.getRecordedBy() != null) existing.setRecordedBy(record.getRecordedBy());
                return attendanceRepo.save(existing);
            })
            .orElseGet(() -> attendanceRepo.save(record));
    }
}
