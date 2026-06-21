package com.estudiez.backend.controller;

import com.estudiez.backend.entity.FeedbackTicket;
import com.estudiez.backend.service.FeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    @GetMapping
    public List<FeedbackTicket> getAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) UUID senderUserId) {
        if (senderUserId != null) return feedbackService.findBySender(senderUserId);
        if (status != null) return feedbackService.findByStatus(status);
        return feedbackService.findAll();
    }

    @GetMapping("/{id}")
    public FeedbackTicket getById(@PathVariable Integer id) { return feedbackService.findById(id); }

    @PostMapping
    public ResponseEntity<FeedbackTicket> create(@RequestBody FeedbackTicket ticket) {
        return ResponseEntity.status(HttpStatus.CREATED).body(feedbackService.create(ticket));
    }

    @PatchMapping("/{id}")
    public FeedbackTicket update(@PathVariable Integer id, @RequestBody FeedbackTicket ticket) {
        return feedbackService.update(id, ticket);
    }
}
