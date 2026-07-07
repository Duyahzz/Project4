package com.estudiez.backend.service;

import com.estudiez.backend.entity.Assessment;
import com.estudiez.backend.entity.StudentMark;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.AssessmentRepository;
import com.estudiez.backend.repository.StudentMarkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AssessmentService {

    private final AssessmentRepository assessmentRepo;
    private final StudentMarkRepository studentMarkRepo;

    public List<Assessment> findAll() { return assessmentRepo.findAll(); }

    public Assessment findById(Integer id) {
        return assessmentRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Assessment", id));
    }

    public List<Assessment> findByClass(Integer classId) { return assessmentRepo.findByClassId(classId); }
    public List<Assessment> findByTeacher(UUID teacherId) { return assessmentRepo.findByTeacherId(teacherId); }

    public Assessment create(Assessment assessment) { return assessmentRepo.save(assessment); }

    public Assessment update(Integer id, Assessment updated) {
        Assessment assessment = findById(id);
        assessment.setTitle(updated.getTitle());
        assessment.setAssessmentDate(updated.getAssessmentDate());
        assessment.setMaxScore(updated.getMaxScore());
        assessment.setWeight(updated.getWeight());
        assessment.setDescription(updated.getDescription());
        return assessmentRepo.save(assessment);
    }

    public void delete(Integer id) {
        if (!assessmentRepo.existsById(id)) throw new ResourceNotFoundException("Assessment", id);
        assessmentRepo.deleteById(id);
    }

    // Student Marks
    public List<StudentMark> findMarksByAssessment(Integer assessmentId) {
        return studentMarkRepo.findByAssessmentId(assessmentId);
    }

    public List<StudentMark> findMarksByStudent(UUID studentId) {
        return studentMarkRepo.findByStudentId(studentId);
    }

    public StudentMark saveMark(StudentMark mark) {
        Optional<StudentMark> existing = studentMarkRepo.findByAssessmentIdAndStudentId(mark.getAssessmentId(), mark.getStudentId());
        if (existing.isPresent()) {
            StudentMark em = existing.get();
            em.setScore(mark.getScore());
            em.setTeacherComment(mark.getTeacherComment());
            em.setRemark(mark.getRemark());
            em.setGradedBy(mark.getGradedBy());
            return studentMarkRepo.save(em);
        }
        return studentMarkRepo.save(mark);
    }
}
