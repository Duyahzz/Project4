package com.estudiez.backend.service;

import com.estudiez.backend.entity.Teacher;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TeacherService {

    private final TeacherRepository teacherRepo;

    public List<Teacher> findAll() { return teacherRepo.findAll(); }

    public Teacher findById(UUID id) {
        return teacherRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Teacher", id));
    }

    public List<Teacher> findBySubject(Integer subjectId) { return teacherRepo.findBySubjectId(subjectId); }

    public Teacher create(Teacher teacher) { return teacherRepo.save(teacher); }

    public Teacher update(UUID id, Teacher updated) {
        Teacher teacher = findById(id);
        teacher.setQualification(updated.getQualification());
        teacher.setSubjectId(updated.getSubjectId());
        return teacherRepo.save(teacher);
    }

    public void delete(UUID id) {
        if (!teacherRepo.existsById(id)) throw new ResourceNotFoundException("Teacher", id);
        teacherRepo.deleteById(id);
    }
}



