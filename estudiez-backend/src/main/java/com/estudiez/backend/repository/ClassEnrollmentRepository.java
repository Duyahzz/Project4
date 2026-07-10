package com.estudiez.backend.repository;

import com.estudiez.backend.entity.ClassEnrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ClassEnrollmentRepository extends JpaRepository<ClassEnrollment, Integer> {
    List<ClassEnrollment> findByClassId(Integer classId);
    List<ClassEnrollment> findByStudentId(UUID studentId);
    List<ClassEnrollment> findByStudentIdAndStatus(UUID studentId, String status);
    long countByClassIdAndStatus(Integer classId, String status);
}
