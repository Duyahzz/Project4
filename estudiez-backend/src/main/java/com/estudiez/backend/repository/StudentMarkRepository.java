package com.estudiez.backend.repository;

import com.estudiez.backend.entity.StudentMark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface StudentMarkRepository extends JpaRepository<StudentMark, Integer> {
    List<StudentMark> findByStudentId(UUID studentId);
    List<StudentMark> findByAssessmentId(Integer assessmentId);
    Optional<StudentMark> findByAssessmentIdAndStudentId(Integer assessmentId, UUID studentId);
}
