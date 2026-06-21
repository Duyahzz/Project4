package com.estudiez.backend.service;

import com.estudiez.backend.entity.TimetableSlot;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.TimetableSlotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TimetableService {

    private final TimetableSlotRepository timetableRepo;

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
}
