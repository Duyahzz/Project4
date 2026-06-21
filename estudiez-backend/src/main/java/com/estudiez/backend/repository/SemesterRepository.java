package com.estudiez.backend.repository;
import com.estudiez.backend.entity.Semester;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
import java.util.List;

@Repository
public interface SemesterRepository extends JpaRepository<Semester, Integer> {
    List<Semester> findBySchoolYearId(Integer schoolYearId);
}
