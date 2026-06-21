package com.estudiez.backend.entity;

import com.estudiez.backend.entity.embeddable.ChatGroupMemberId;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "ChatGroupMembers")
public class ChatGroupMember {
    @EmbeddedId
    private ChatGroupMemberId id;
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime joinedAt;
    private LocalDateTime leftAt;
}

