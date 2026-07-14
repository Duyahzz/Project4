package com.estudiez.backend.controller;

import com.estudiez.backend.entity.Semester;
import com.estudiez.backend.repository.SemesterRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/semesters")
@Tag(name = "Semesters")
public class SemesterController {

    private final SemesterRepository semesterRepository;

    @GetMapping
    @Operation(summary = "Get all semesters")
    public List<Semester> getAll() {
        return semesterRepository.findAll();
    }
}
