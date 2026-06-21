package com.estudiez.backend.repository;
import com.estudiez.backend.entity.AssessmentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
import java.util.Optional;

@Repository
public interface AssessmentTypeRepository extends JpaRepository<AssessmentType, Integer> {
    Optional<AssessmentType> findByCode(String code);
}
