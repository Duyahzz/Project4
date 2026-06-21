package com.estudiez.backend.service;

import com.estudiez.backend.entity.StudyResource;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.StudyResourceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StudyResourceService {

    private final StudyResourceRepository resourceRepo;

    public List<StudyResource> findAll() { return resourceRepo.findAll(); }

    public List<StudyResource> findBySubject(Integer subjectId) {
        return resourceRepo.findAll().stream()
                .filter(r -> subjectId.equals(r.getSubjectId()))
                .toList();
    }

    public List<StudyResource> findByClass(Integer classId) {
        return resourceRepo.findAll().stream()
                .filter(r -> classId.equals(r.getClassId()))
                .toList();
    }

    public StudyResource findById(Integer id) {
        return resourceRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("StudyResource", id));
    }

    public StudyResource create(StudyResource resource) { return resourceRepo.save(resource); }

    public StudyResource update(Integer id, StudyResource updated) {
        StudyResource resource = findById(id);
        resource.setTitle(updated.getTitle());
        resource.setDescription(updated.getDescription());
        resource.setResourceType(updated.getResourceType());
        resource.setFileUrl(updated.getFileUrl());
        resource.setThumbnailUrl(updated.getThumbnailUrl());
        resource.setVisibility(updated.getVisibility());
        resource.setSubjectId(updated.getSubjectId());
        resource.setClassId(updated.getClassId());
        return resourceRepo.save(resource);
    }

    public void delete(Integer id) {
        if (!resourceRepo.existsById(id)) throw new ResourceNotFoundException("StudyResource", id);
        resourceRepo.deleteById(id);
    }
}
