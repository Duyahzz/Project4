package com.estudiez.backend.service;

import com.estudiez.backend.entity.*;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TimetableService {

    private final TimetableSlotRepository timetableRepo;
    private final SchoolClassRepository classRepo;
    private final SemesterRepository semesterRepo;
    private final SchoolYearRepository schoolYearRepo;
    private final LessonSessionRepository lessonSessionRepo;
    private final TeacherRepository teacherRepo;
    private final UserRepository userRepo;
    private final SubjectRepository subjectRepo;

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

    @Transactional
    public TimetableSlot create(TimetableSlot slot) {
        validateConflicts(slot);
        TimetableSlot saved = timetableRepo.save(slot);
        generateLessonSessions(saved);
        return saved;
    }

    @Transactional
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

        validateConflicts(slot);
        slot = timetableRepo.save(slot);

        deleteFutureScheduledSessions(slot.getTimetableSlotId());
        generateLessonSessions(slot);

        return slot;
    }

    @Transactional
    public void delete(Integer id) {
        TimetableSlot slot = findById(id);
        deleteFutureScheduledSessions(id);

        List<LessonSession> sessions = lessonSessionRepo.findByTimetableSlotId(id);
        for (LessonSession s : sessions) {
            s.setTimetableSlotId(null);
            lessonSessionRepo.save(s);
        }

        timetableRepo.delete(slot);
    }
 
    @Transactional
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
 
                TimetableSlot savedSlot = timetableRepo.save(newSlot);
                generateLessonSessions(savedSlot);
                clonedCount++;
            }
        }
        return clonedCount;
    }

    private void validateConflicts(TimetableSlot slot) {
        List<TimetableSlot> overlaps = timetableRepo.findOverlappingSlots(
                slot.getDayOfWeek(),
                slot.getPeriodNo(),
                slot.getEffectiveFrom(),
                slot.getEffectiveTo()
        );

        for (TimetableSlot existing : overlaps) {
            if (slot.getTimetableSlotId() != null && slot.getTimetableSlotId().equals(existing.getTimetableSlotId())) {
                continue;
            }

            // 1. Class conflict
            if (existing.getClassId().equals(slot.getClassId())) {
                String className = classRepo.findById(slot.getClassId())
                        .map(SchoolClass::getName)
                        .orElse("Lớp học");
                String subjectName = subjectRepo.findById(existing.getSubjectId())
                        .map(Subject::getName)
                        .orElse("Môn học");
                throw new IllegalArgumentException(String.format(
                        "Lớp %s đã có lịch học môn %s vào Tiết %d %s",
                        className, subjectName, slot.getPeriodNo(), formatDayOfWeek(slot.getDayOfWeek())
                ));
            }

            // 2. Teacher conflict (only if not Physical Education)
            boolean isPhysicalEducation = isPeSubject(slot.getSubjectId()) || isPeSubject(existing.getSubjectId());
            if (!isPhysicalEducation && existing.getTeacherId().equals(slot.getTeacherId())) {
                String teacherName = getTeacherName(slot.getTeacherId());
                String existingClassName = classRepo.findById(existing.getClassId())
                        .map(SchoolClass::getName)
                        .orElse("Lớp khác");
                throw new IllegalArgumentException(String.format(
                        "Giáo viên %s đã bận dạy lớp %s vào Tiết %d %s",
                        teacherName, existingClassName, slot.getPeriodNo(), formatDayOfWeek(slot.getDayOfWeek())
                ));
            }

            // 3. Room conflict (only if not GYM/yard and not empty)
            if (slot.getRoom() != null && !slot.getRoom().trim().isEmpty() &&
                existing.getRoom() != null && !existing.getRoom().trim().isEmpty()) {
                String room = slot.getRoom().trim();
                boolean isGymOrYard = room.equalsIgnoreCase("GYM") || room.toLowerCase().contains("yard");
                if (!isGymOrYard && room.equalsIgnoreCase(existing.getRoom().trim())) {
                    String className = classRepo.findById(existing.getClassId())
                            .map(SchoolClass::getName)
                            .orElse("Lớp khác");
                    throw new IllegalArgumentException(String.format(
                            "Phòng %s đã được sử dụng bởi lớp %s vào Tiết %d %s",
                            slot.getRoom(), className, slot.getPeriodNo(), formatDayOfWeek(slot.getDayOfWeek())
                    ));
                }
            }
        }
    }

    private boolean isPeSubject(Integer subjectId) {
        if (subjectId == null) return false;
        return subjectRepo.findById(subjectId)
                .map(sub -> "PE".equalsIgnoreCase(sub.getCode()) || 
                            "Physical Education".equalsIgnoreCase(sub.getName()) || 
                            "Thể dục".equalsIgnoreCase(sub.getName()))
                .orElse(false);
    }

    private String getTeacherName(UUID teacherId) {
        if (teacherId == null) return "Giáo viên";
        return teacherRepo.findById(teacherId)
                .flatMap(t -> userRepo.findById(t.getUserId()))
                .map(User::getFullName)
                .orElse("Giáo viên");
    }

    private String formatDayOfWeek(int dayOfWeek) {
        if (dayOfWeek == 7) return "Chủ Nhật";
        if (dayOfWeek == 6) return "Thứ Bảy";
        return "Thứ " + (dayOfWeek + 1);
    }

    private void generateLessonSessions(TimetableSlot slot) {
        Semester semester = semesterRepo.findById(slot.getSemesterId()).orElse(null);
        if (semester == null) return;

        LocalDate semStart = semester.getStartDate();
        LocalDate semEnd = semester.getEndDate();

        LocalDate start = slot.getEffectiveFrom() != null ? slot.getEffectiveFrom() : semStart;
        LocalDate end = slot.getEffectiveTo() != null ? slot.getEffectiveTo() : semEnd;

        if (start.isBefore(semStart)) start = semStart;
        if (end.isAfter(semEnd)) end = semEnd;

        LocalDate today = LocalDate.now();
        LocalDate generationStart = start.isBefore(today) ? today : start;

        if (generationStart.isAfter(end)) {
            return;
        }

        List<LocalDate> dates = getDatesForDayOfWeek(generationStart, end, slot.getDayOfWeek());

        for (LocalDate date : dates) {
            LessonSession session = LessonSession.builder()
                    .timetableSlotId(slot.getTimetableSlotId())
                    .classId(slot.getClassId())
                    .subjectId(slot.getSubjectId())
                    .teacherId(slot.getTeacherId())
                    .sessionDate(date)
                    .periodNo(slot.getPeriodNo())
                    .room(slot.getRoom())
                    .status("SCHEDULED")
                    .build();
            lessonSessionRepo.save(session);
        }
    }

    private List<LocalDate> getDatesForDayOfWeek(LocalDate start, LocalDate end, int targetDayOfWeek) {
        List<LocalDate> dates = new java.util.ArrayList<>();
        java.time.DayOfWeek targetDay = java.time.DayOfWeek.of(targetDayOfWeek);
        
        LocalDate current = start;
        while (!current.isAfter(end)) {
            if (current.getDayOfWeek() == targetDay) {
                dates.add(current);
            }
            current = current.plusDays(1);
        }
        return dates;
    }

    private void deleteFutureScheduledSessions(Integer timetableSlotId) {
        List<LessonSession> futureScheduled = lessonSessionRepo.findByTimetableSlotId(timetableSlotId).stream()
                .filter(s -> !s.getSessionDate().isBefore(LocalDate.now()) && "SCHEDULED".equalsIgnoreCase(s.getStatus()))
                .toList();
        lessonSessionRepo.deleteAll(futureScheduled);
    }
}
