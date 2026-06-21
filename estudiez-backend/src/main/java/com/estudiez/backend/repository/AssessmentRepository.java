package com.estudiez.backend.repository;

import com.estudiez.backend.entity.Assessment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface AssessmentRepository extends JpaRepository<Assessment, Integer> {
    List<Assessment> findByClassId(Integer classId);
    List<Assessment> findByTeacherId(UUID teacherId);
    List<Assessment> findBySubjectIdAndSemesterId(Integer subjectId, Integer semesterId);
}
