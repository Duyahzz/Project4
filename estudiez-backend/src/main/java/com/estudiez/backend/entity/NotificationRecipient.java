package com.estudiez.backend.entity;

import com.estudiez.backend.entity.embeddable.NotificationRecipientId;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "NotificationRecipients")
public class NotificationRecipient {
    @EmbeddedId
    private NotificationRecipientId id;
    private LocalDateTime readAt;
}

