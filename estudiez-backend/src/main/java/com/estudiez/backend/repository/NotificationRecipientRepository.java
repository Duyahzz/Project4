package com.estudiez.backend.repository;

import com.estudiez.backend.entity.NotificationRecipient;
import com.estudiez.backend.entity.embeddable.NotificationRecipientId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRecipientRepository extends JpaRepository<NotificationRecipient, NotificationRecipientId> {
    List<NotificationRecipient> findByIdUserId(UUID userId);
    List<NotificationRecipient> findByIdUserIdAndReadAtIsNull(UUID userId);
}

