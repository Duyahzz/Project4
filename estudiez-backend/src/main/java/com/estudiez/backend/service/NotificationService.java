package com.estudiez.backend.service;

import com.estudiez.backend.entity.Notification;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepo;

    public List<Notification> findAll() { return notificationRepo.findAll(); }

    public List<Notification> findByTargetType(String targetType) {
        return notificationRepo.findAll().stream()
                .filter(n -> targetType.equalsIgnoreCase(n.getTargetType()))
                .toList();
    }

    public List<Notification> findByTargetTypeAndTargetId(String targetType, String targetId) {
        return notificationRepo.findAll().stream()
                .filter(n -> targetType.equalsIgnoreCase(n.getTargetType())
                        && targetId.equals(n.getTargetId()))
                .toList();
    }

    public Notification findById(Integer id) {
        return notificationRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", id));
    }

    public Notification create(Notification notification) { return notificationRepo.save(notification); }

    public void delete(Integer id) {
        if (!notificationRepo.existsById(id)) throw new ResourceNotFoundException("Notification", id);
        notificationRepo.deleteById(id);
    }
}
