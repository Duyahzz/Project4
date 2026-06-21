package com.estudiez.backend.controller;

import com.estudiez.backend.entity.Notification;
import com.estudiez.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public List<Notification> getAll(
            @RequestParam(required = false) String targetType,
            @RequestParam(required = false) String targetId) {
        if (targetType != null && targetId != null)
            return notificationService.findByTargetTypeAndTargetId(targetType, targetId);
        if (targetType != null)
            return notificationService.findByTargetType(targetType);
        return notificationService.findAll();
    }

    @GetMapping("/{id}")
    public Notification getById(@PathVariable Integer id) { return notificationService.findById(id); }

    @PostMapping
    public ResponseEntity<Notification> create(@RequestBody Notification notification) {
        return ResponseEntity.status(HttpStatus.CREATED).body(notificationService.create(notification));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        notificationService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
