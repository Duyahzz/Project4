package com.estudiez.backend.entity;

import com.estudiez.backend.entity.embeddable.StudentParentLinkId;
import jakarta.persistence.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "StudentParentLinks")
public class StudentParentLink {
    @EmbeddedId
    private StudentParentLinkId id;

    @Column(nullable = false, length = 50)
    private String relationship;

    @Column(nullable = false)
    private Boolean isPrimaryContact = false;
}

