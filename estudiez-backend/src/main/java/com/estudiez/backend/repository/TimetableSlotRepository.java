package com.estudiez.backend.repository;
import com.estudiez.backend.entity.TimetableSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
@Repository
public interface TimetableSlotRepository extends JpaRepository<TimetableSlot, Integer> {
    @Query("SELECT t FROM TimetableSlot t WHERE t.dayOfWeek = :dayOfWeek AND t.periodNo = :periodNo " +
           "AND (t.effectiveFrom <= :effectiveTo OR :effectiveTo IS NULL) " +
           "AND (:effectiveFrom <= t.effectiveTo OR t.effectiveTo IS NULL)")
    List<TimetableSlot> findOverlappingSlots(
            @Param("dayOfWeek") Integer dayOfWeek,
            @Param("periodNo") Integer periodNo,
            @Param("effectiveFrom") LocalDate effectiveFrom,
            @Param("effectiveTo") LocalDate effectiveTo);
}
