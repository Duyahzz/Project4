package com.estudiez.backend.repository;

import com.estudiez.backend.entity.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeacherRepository extends JpaRepository<Teacher, UUID> {
    Optional<Teacher> findByUserId(UUID userId);
    Optional<Teacher> findByEmployeeCode(String employeeCode);
    List<Teacher> findBySubjectId(Integer subjectId);
}
