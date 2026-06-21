package com.estudiez.backend.repository;

import com.estudiez.backend.entity.StudentParentLink;
import com.estudiez.backend.entity.embeddable.StudentParentLinkId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface StudentParentLinkRepository extends JpaRepository<StudentParentLink, StudentParentLinkId> {
    List<StudentParentLink> findByIdStudentId(UUID studentId);
    List<StudentParentLink> findByIdParentId(UUID parentId);
}

