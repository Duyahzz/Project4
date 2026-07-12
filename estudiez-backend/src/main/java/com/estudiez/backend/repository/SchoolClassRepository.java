package com.estudiez.backend.repository;

import com.estudiez.backend.entity.SchoolClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SchoolClassRepository extends JpaRepository<SchoolClass, Integer> {
    List<SchoolClass> findBySchoolYearId(Integer schoolYearId);
    List<SchoolClass> findByIsActive(Boolean isActive);

    /** Used to detect duplicates before insert (create) */
    boolean existsBySchoolYearIdAndNameAndTrainingProgram(
            Integer schoolYearId, String name, String trainingProgram);

    /** Used to detect duplicates before update (excludes the class being edited) */
    boolean existsBySchoolYearIdAndNameAndTrainingProgramAndClassIdNot(
            Integer schoolYearId, String name, String trainingProgram, Integer classId);
}
