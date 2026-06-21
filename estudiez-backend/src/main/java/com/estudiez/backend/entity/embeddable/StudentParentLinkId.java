package com.estudiez.backend.entity.embeddable;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;
import java.io.Serializable;
import java.util.UUID;

@Embeddable
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
public class StudentParentLinkId implements Serializable {
    @Column(columnDefinition = "uniqueidentifier")
    private UUID studentId;
    @Column(columnDefinition = "uniqueidentifier")
    private UUID parentId;
}

