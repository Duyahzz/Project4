package com.estudiez.backend.repository;

import com.estudiez.backend.entity.StudentGradeProgression;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface StudentGradeProgressionRepository extends JpaRepository<StudentGradeProgression, Integer> {
    List<StudentGradeProgression> findByStudentId(UUID studentId);
    List<StudentGradeProgression> findBySchoolYearId(Integer schoolYearId);
    List<StudentGradeProgression> findByStudentIdAndSchoolYearId(UUID studentId, Integer schoolYearId);
}
