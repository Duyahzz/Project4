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

    public SchoolClass create(SchoolClass schoolClass) { return classRepo.save(schoolClass); }

    public SchoolClass update(Integer id, SchoolClass updated) {
        SchoolClass sc = findById(id);
        sc.setName(updated.getName());
        sc.setRoom(updated.getRoom());
        sc.setHomeroomTeacherId(updated.getHomeroomTeacherId());
        sc.setIsActive(updated.getIsActive());
        sc.setTrainingProgram(updated.getTrainingProgram());
        return classRepo.save(sc);
    }

    public void delete(Integer id) {
        if (!classRepo.existsById(id)) throw new ResourceNotFoundException("Class", id);
        classRepo.deleteById(id);
    }
}



