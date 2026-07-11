package com.estudiez.backend.service;

import com.estudiez.backend.entity.SchoolClass;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.SchoolClassRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SchoolClassService {

    private final SchoolClassRepository classRepo;

    public List<SchoolClass> findAll() { return classRepo.findAll(); }

    public SchoolClass findById(Integer id) {
        return classRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Class", id));
    }

    public List<SchoolClass> findBySchoolYear(Integer schoolYearId) {
        return classRepo.findBySchoolYearId(schoolYearId);
    }

    public SchoolClass create(SchoolClass schoolClass) {
        String program = schoolClass.getTrainingProgram() == null ? "REGULAR" : schoolClass.getTrainingProgram();
        if (classRepo.existsBySchoolYearIdAndNameAndTrainingProgram(
                schoolClass.getSchoolYearId(), schoolClass.getName(), program)) {
            throw new IllegalArgumentException(
                "A class named '" + schoolClass.getName() + "' with training program '" + program
                + "' already exists in this school year.");
        }
        return classRepo.save(schoolClass);
    }

    public SchoolClass update(Integer id, SchoolClass updated) {
        SchoolClass sc = findById(id);
        String program = updated.getTrainingProgram() == null ? sc.getTrainingProgram() : updated.getTrainingProgram();
        String name    = updated.getName() == null ? sc.getName() : updated.getName();

        if (classRepo.existsBySchoolYearIdAndNameAndTrainingProgramAndClassIdNot(
                sc.getSchoolYearId(), name, program, id)) {
            throw new IllegalArgumentException(
                "A class named '" + name + "' with training program '" + program
                + "' already exists in this school year.");
        }

        sc.setName(updated.getName());
        sc.setRoom(updated.getRoom());
        sc.setHomeroomTeacherId(updated.getHomeroomTeacherId());
        if (updated.getIsActive() != null) {
            sc.setIsActive(updated.getIsActive());
        }
        if (updated.getTrainingProgram() != null) {
            sc.setTrainingProgram(updated.getTrainingProgram());
        }
        if (updated.getStudentLimit() != null) {
            sc.setStudentLimit(updated.getStudentLimit());
        }
        return classRepo.save(sc);
    }

    public void delete(Integer id) {
        if (!classRepo.existsById(id)) throw new ResourceNotFoundException("Class", id);
        classRepo.deleteById(id);
    }
}
