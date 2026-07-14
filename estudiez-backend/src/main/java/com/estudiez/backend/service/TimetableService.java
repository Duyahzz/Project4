package com.estudiez.backend.service;

import com.estudiez.backend.entity.TimetableSlot;
import com.estudiez.backend.entity.SchoolClass;
import com.estudiez.backend.entity.Semester;
import com.estudiez.backend.entity.SchoolYear;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.TimetableSlotRepository;
import com.estudiez.backend.repository.SchoolClassRepository;
import com.estudiez.backend.repository.SemesterRepository;
import com.estudiez.backend.repository.SchoolYearRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TimetableService {

    private final TimetableSlotRepository timetableRepo;
    private final SchoolClassRepository classRepo;
    private final SemesterRepository semesterRepo;
    private final SchoolYearRepository schoolYearRepo;

    public List<TimetableSlot> findAll() { return timetableRepo.findAll(); }

    public List<TimetableSlot> findByClass(Integer classId) {
        return timetableRepo.findAll().stream()
                .filter(s -> classId.equals(s.getClassId()))
                .toList();
    }

    public List<TimetableSlot> findByClassAndSemester(Integer classId, Integer semesterId) {
        return timetableRepo.findAll().stream()
                .filter(s -> classId.equals(s.getClassId()) && semesterId.equals(s.getSemesterId()))
                .toList();
    }

    public TimetableSlot findById(Integer id) {
        return timetableRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("TimetableSlot", id));
    }

    public TimetableSlot create(TimetableSlot slot) { return timetableRepo.save(slot); }

    public TimetableSlot update(Integer id, TimetableSlot updated) {
        TimetableSlot slot = findById(id);
        slot.setClassId(updated.getClassId());
        slot.setSubjectId(updated.getSubjectId());
        slot.setTeacherId(updated.getTeacherId());
        slot.setSemesterId(updated.getSemesterId());
        slot.setDayOfWeek(updated.getDayOfWeek());
        slot.setPeriodNo(updated.getPeriodNo());
        slot.setStartTime(updated.getStartTime());
        slot.setEndTime(updated.getEndTime());
        slot.setRoom(updated.getRoom());
        slot.setEffectiveFrom(updated.getEffectiveFrom());
        slot.setEffectiveTo(updated.getEffectiveTo());
        return timetableRepo.save(slot);
    }

    public void delete(Integer id) {
        if (!timetableRepo.existsById(id)) throw new ResourceNotFoundException("TimetableSlot", id);
        timetableRepo.deleteById(id);
    }
 
    @org.springframework.transaction.annotation.Transactional
    public int cloneTimetableSlots(Integer sourceYearId, Integer targetYearId) {
        List<SchoolClass> sourceClasses = classRepo.findAll().stream()
                .filter(c -> sourceYearId.equals(c.getSchoolYearId()))
                .toList();
        List<SchoolClass> targetClasses = classRepo.findAll().stream()
                .filter(c -> targetYearId.equals(c.getSchoolYearId()))
                .toList();
 
        List<Semester> sourceSemesters = semesterRepo.findAll().stream()
                .filter(s -> sourceYearId.equals(s.getSchoolYearId()))
                .toList();
        List<Semester> targetSemesters = semesterRepo.findAll().stream()
                .filter(s -> targetYearId.equals(s.getSchoolYearId()))
                .toList();
 
        SchoolYear targetYear = schoolYearRepo.findById(targetYearId).orElse(null);
        if (targetYear == null) return 0;
 
        int clonedCount = 0;
 
        for (SchoolClass targetClass : targetClasses) {
            SchoolClass sourceClass = sourceClasses.stream()
                    .filter(sc -> targetClass.getName().equalsIgnoreCase(sc.getName()))
                    .findFirst()
                    .orElse(null);
 
            if (sourceClass == null) continue;
 
            // Prevent duplicate cloning if target class already has timetable slots
            List<TimetableSlot> targetSlots = findByClass(targetClass.getClassId());
            if (!targetSlots.isEmpty()) continue;
 
            List<TimetableSlot> sourceSlots = findByClass(sourceClass.getClassId());
 
            for (TimetableSlot oldSlot : sourceSlots) {
                Semester oldSem = sourceSemesters.stream()
                        .filter(s -> oldSlot.getSemesterId().equals(s.getSemesterId()))
                        .findFirst()
                        .orElse(null);
 
                if (oldSem == null) continue;
 
                Semester newSem = targetSemesters.stream()
                        .filter(s -> oldSem.getName().equalsIgnoreCase(s.getName()))
                        .findFirst()
                        .orElse(null);
 
                if (newSem == null) continue;
 
                TimetableSlot newSlot = TimetableSlot.builder()
                        .classId(targetClass.getClassId())
                        .subjectId(oldSlot.getSubjectId())
                        .teacherId(oldSlot.getTeacherId())
                        .semesterId(newSem.getSemesterId())
                        .dayOfWeek(oldSlot.getDayOfWeek())
                        .periodNo(oldSlot.getPeriodNo())
                        .startTime(oldSlot.getStartTime())
                        .endTime(oldSlot.getEndTime())
                        .room(targetClass.getRoom() != null ? targetClass.getRoom() : oldSlot.getRoom())
                        .effectiveFrom(newSem.getStartDate())
                        .effectiveTo(newSem.getEndDate())
                        .build();
 
                timetableRepo.save(newSlot);
                clonedCount++;
            }
        }
        return clonedCount;
    }
}
