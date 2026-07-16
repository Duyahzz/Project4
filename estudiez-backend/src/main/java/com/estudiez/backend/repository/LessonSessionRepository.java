package com.estudiez.backend.repository;

import com.estudiez.backend.entity.LessonSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface LessonSessionRepository extends JpaRepository<LessonSession, Integer> {
    List<LessonSession> findByClassId(Integer classId);
    List<LessonSession> findByTeacherId(UUID teacherId);
    List<LessonSession> findByClassIdAndStatus(Integer classId, String status);
    List<LessonSession> findByTimetableSlotId(Integer timetableSlotId);
}
