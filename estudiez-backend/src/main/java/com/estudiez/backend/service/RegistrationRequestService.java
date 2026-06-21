package com.estudiez.backend.service;

import com.estudiez.backend.entity.RegistrationRequest;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.RegistrationRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RegistrationRequestService {

    private final RegistrationRequestRepository requestRepo;

    public List<RegistrationRequest> findAll() { return requestRepo.findAll(); }

    public List<RegistrationRequest> findByStatus(String status) { return requestRepo.findByStatus(status); }

    public RegistrationRequest findById(Integer id) {
        return requestRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("RegistrationRequest", id));
    }

    public RegistrationRequest submit(RegistrationRequest request) {
        request.setStatus("PENDING");
        return requestRepo.save(request);
    }

    public RegistrationRequest approve(Integer id, UUID reviewedBy, String reviewNotes) {
        RegistrationRequest req = findById(id);
        req.setStatus("APPROVED");
        req.setReviewedBy(reviewedBy);
        req.setReviewNotes(reviewNotes);
        req.setReviewedAt(LocalDateTime.now());
        return requestRepo.save(req);
    }

    public RegistrationRequest reject(Integer id, UUID reviewedBy, String reviewNotes) {
        RegistrationRequest req = findById(id);
        req.setStatus("REJECTED");
        req.setReviewedBy(reviewedBy);
        req.setReviewNotes(reviewNotes);
        req.setReviewedAt(LocalDateTime.now());
        return requestRepo.save(req);
    }
}

