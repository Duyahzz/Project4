package com.estudiez.backend.repository;

import com.estudiez.backend.entity.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Integer> {
    List<AttendanceRecord> findByLessonSessionId(Integer lessonSessionId);
    List<AttendanceRecord> findByStudentId(UUID studentId);
    Optional<AttendanceRecord> findByLessonSessionIdAndStudentId(Integer lessonSessionId, UUID studentId);
}
