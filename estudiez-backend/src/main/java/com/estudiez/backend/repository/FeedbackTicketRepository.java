package com.estudiez.backend.repository;
import com.estudiez.backend.entity.FeedbackTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
@Repository
public interface FeedbackTicketRepository extends JpaRepository<FeedbackTicket, Integer> {}
