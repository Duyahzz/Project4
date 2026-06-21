package com.estudiez.backend.entity.embeddable;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;
import java.io.Serializable;
import java.util.UUID;

@Embeddable
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
public class NotificationRecipientId implements Serializable {
    private Integer notificationId;
    @Column(columnDefinition = "uniqueidentifier")
    private UUID userId;
}

