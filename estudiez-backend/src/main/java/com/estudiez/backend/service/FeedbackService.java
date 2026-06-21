package com.estudiez.backend.service;

import com.estudiez.backend.entity.FeedbackTicket;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.FeedbackTicketRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FeedbackService {

    private final FeedbackTicketRepository feedbackRepo;

    public List<FeedbackTicket> findAll() { return feedbackRepo.findAll(); }

    public List<FeedbackTicket> findByStatus(String status) {
        return feedbackRepo.findAll().stream()
                .filter(f -> status.equalsIgnoreCase(f.getStatus()))
                .toList();
    }

    public List<FeedbackTicket> findBySender(UUID senderUserId) {
        return feedbackRepo.findAll().stream()
                .filter(f -> senderUserId.equals(f.getSenderUserId()))
                .toList();
    }

    public FeedbackTicket findById(Integer id) {
        return feedbackRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("FeedbackTicket", id));
    }

    public FeedbackTicket create(FeedbackTicket ticket) {
        ticket.setStatus("OPEN");
        return feedbackRepo.save(ticket);
    }

    public FeedbackTicket update(Integer id, FeedbackTicket updated) {
        FeedbackTicket ticket = findById(id);
        ticket.setStatus(updated.getStatus());
        ticket.setAdminResponse(updated.getAdminResponse());
        ticket.setHandledBy(updated.getHandledBy());
        if (updated.getHandledAt() != null) ticket.setHandledAt(updated.getHandledAt());
        return feedbackRepo.save(ticket);
    }
}
