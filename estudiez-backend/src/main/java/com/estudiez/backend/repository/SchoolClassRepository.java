package com.estudiez.backend.repository;

import com.estudiez.backend.entity.SchoolClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SchoolClassRepository extends JpaRepository<SchoolClass, Integer> {
    List<SchoolClass> findBySchoolYearId(Integer schoolYearId);
    List<SchoolClass> findByIsActive(Boolean isActive);
}
