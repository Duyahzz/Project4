package com.estudiez.backend.service;

import com.estudiez.backend.entity.Student;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepo;

    public List<Student> findAll() { return studentRepo.findAll(); }

    public Student findById(UUID id) {
        return studentRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Student", id));
    }

    public Student findByCode(String code) {
        return studentRepo.findByStudentCode(code)
            .orElseThrow(() -> new ResourceNotFoundException("Student not found with code: " + code));
    }

    public List<Student> findByStatus(String status) { return studentRepo.findByStatus(status); }

    public Student create(Student student) { return studentRepo.save(student); }

    public Student update(UUID id, Student updated) {
        Student student = findById(id);
        student.setDateOfBirth(updated.getDateOfBirth());
        student.setGender(updated.getGender());
        student.setAddress(updated.getAddress());
        student.setStatus(updated.getStatus());
        return studentRepo.save(student);
    }

    public void delete(UUID id) {
        if (!studentRepo.existsById(id)) throw new ResourceNotFoundException("Student", id);
        studentRepo.deleteById(id);
    }
}
