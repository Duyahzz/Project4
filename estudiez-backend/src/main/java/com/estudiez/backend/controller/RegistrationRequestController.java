package com.estudiez.backend.controller;

import com.estudiez.backend.entity.RegistrationRequest;
import com.estudiez.backend.service.RegistrationRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/registrations")
@RequiredArgsConstructor
public class RegistrationRequestController {

    private final RegistrationRequestService requestService;

    @GetMapping
    public List<RegistrationRequest> getAll(@RequestParam(required = false) String status) {
        return status != null ? requestService.findByStatus(status) : requestService.findAll();
    }

    @GetMapping("/{id}")
    public RegistrationRequest getById(@PathVariable Integer id) {
        return requestService.findById(id);
    }

    // Public endpoint – no auth needed
    @PostMapping
    public ResponseEntity<RegistrationRequest> submit(@RequestBody RegistrationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(requestService.submit(request));
    }

    @PatchMapping("/{id}/approve")
    public RegistrationRequest approve(@PathVariable Integer id,
                                       @RequestBody(required = false) Map<String, String> body) {
        UUID reviewedBy = (body != null && body.get("reviewedBy") != null)
                ? UUID.fromString(body.get("reviewedBy")) : null;
        String notes = body != null ? body.getOrDefault("reviewNotes", null) : null;
        return requestService.approve(id, reviewedBy, notes);
    }

    @PatchMapping("/{id}/reject")
    public RegistrationRequest reject(@PathVariable Integer id,
                                      @RequestBody(required = false) Map<String, String> body) {
        UUID reviewedBy = (body != null && body.get("reviewedBy") != null)
                ? UUID.fromString(body.get("reviewedBy")) : null;
        String notes = body != null ? body.getOrDefault("reviewNotes", null) : null;
        return requestService.reject(id, reviewedBy, notes);
    }
}

