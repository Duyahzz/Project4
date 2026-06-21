package com.estudiez.backend.controller;

import com.estudiez.backend.entity.SchoolContact;
import com.estudiez.backend.repository.SchoolContactRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final SchoolContactRepository contactRepo;

    @GetMapping
    public List<SchoolContact> getAll() {
        return contactRepo.findAll().stream()
                .filter(SchoolContact::getIsActive)
                .toList();
    }

    @GetMapping("/{id}")
    public SchoolContact getById(@PathVariable Integer id) {
        return contactRepo.findById(id)
                .orElseThrow(() -> new com.estudiez.backend.exception.ResourceNotFoundException("SchoolContact", id));
    }

    @PostMapping
    public ResponseEntity<SchoolContact> create(@RequestBody SchoolContact contact) {
        return ResponseEntity.status(HttpStatus.CREATED).body(contactRepo.save(contact));
    }

    @PutMapping("/{id}")
    public SchoolContact update(@PathVariable Integer id, @RequestBody SchoolContact updated) {
        SchoolContact contact = getById(id);
        contact.setName(updated.getName());
        contact.setEmail(updated.getEmail());
        contact.setPhone(updated.getPhone());
        contact.setAddress(updated.getAddress());
        contact.setWorkingHours(updated.getWorkingHours());
        contact.setIsActive(updated.getIsActive());
        return contactRepo.save(contact);
    }
}
