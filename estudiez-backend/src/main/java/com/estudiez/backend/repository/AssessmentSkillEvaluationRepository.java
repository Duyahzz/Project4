package com.estudiez.backend.repository;
import com.estudiez.backend.entity.AssessmentSkillEvaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
@Repository
public interface AssessmentSkillEvaluationRepository extends JpaRepository<AssessmentSkillEvaluation, Integer> {}
