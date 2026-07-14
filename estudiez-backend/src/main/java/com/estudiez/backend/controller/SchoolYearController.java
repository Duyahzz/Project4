package com.estudiez.backend.controller;

import com.estudiez.backend.entity.SchoolYear;
import com.estudiez.backend.entity.Semester;
import com.estudiez.backend.repository.SchoolYearRepository;
import com.estudiez.backend.repository.SemesterRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/school-years")
@Tag(name = "School Years")
public class SchoolYearController {

    private final SchoolYearRepository schoolYearRepository;
    private final SemesterRepository semesterRepository;

    @GetMapping
    @Operation(summary = "Get all school years")
    public List<SchoolYear> getAll() {
        return schoolYearRepository.findAll();
    }

    /**
     * Find or create a school year by name.
     * Used by the rollover wizard to ensure the target year exists before creating classes in it.
     * If a year with the given name already exists, returns it. Otherwise creates a new one.
     */
    @PostMapping("/find-or-create")
    @Operation(summary = "Find or create a school year by name")
    public ResponseEntity<SchoolYear> findOrCreate(@RequestBody Map<String, String> body) {
        String name = body.get("name");
        if (name == null || name.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        return schoolYearRepository.findAll().stream()
                .filter(sy -> sy.getName().equals(name))
                .findFirst()
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    // Auto-derive start/end dates from format "YYYY-YYYY"
                    LocalDate startDate;
                    LocalDate endDate;
                    try {
                        String[] parts = name.split("-");
                        int startYear = Integer.parseInt(parts[0]);
                        int endYear = Integer.parseInt(parts[1]);
                        startDate = LocalDate.of(startYear, 9, 1);
                        endDate = LocalDate.of(endYear, 8, 31);
                    } catch (Exception e) {
                        startDate = LocalDate.now();
                        endDate = LocalDate.now().plusYears(1);
                    }
                    SchoolYear newYear = SchoolYear.builder()
                            .name(name)
                            .startDate(startDate)
                            .endDate(endDate)
                            .isCurrent(false)
                            .build();
                    SchoolYear saved = schoolYearRepository.save(newYear);

                    // Auto-create Semester 1 and Semester 2 for the new school year
                    Semester sem1 = Semester.builder()
                            .schoolYearId(saved.getSchoolYearId())
                            .name("Semester 1")
                            .startDate(startDate)
                            .endDate(startDate.plusMonths(5))
                            .build();
                    Semester sem2 = Semester.builder()
                            .schoolYearId(saved.getSchoolYearId())
                            .name("Semester 2")
                            .startDate(startDate.plusMonths(6))
                            .endDate(endDate)
                            .build();
                    semesterRepository.save(sem1);
                    semesterRepository.save(sem2);

                    return ResponseEntity.ok(saved);
                });
    }
 
    @PutMapping("/{id}/set-current")
    @Operation(summary = "Set the school year as current active year")
    public ResponseEntity<SchoolYear> setCurrentYear(@PathVariable Integer id) {
        return schoolYearRepository.findById(id)
                .map(sy -> {
                    // Set all other school years to not current
                    schoolYearRepository.findAll().forEach(other -> {
                        if (other.getIsCurrent() != null && other.getIsCurrent()) {
                            other.setIsCurrent(false);
                            schoolYearRepository.save(other);
                        }
                    });
                    sy.setIsCurrent(true);
                    return ResponseEntity.ok(schoolYearRepository.save(sy));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
