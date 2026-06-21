package com.estudiez.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity @Table(name = "SchoolContacts")
public class SchoolContact {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer schoolContactId;
    @Column(nullable = false, length = 150)
    private String name;
    @Column(length = 150)
    private String email;
    @Column(length = 30)
    private String phone;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String address;
    @Column(length = 255)
    private String workingHours;
    @Column(nullable = false)
    private Boolean isActive = true;
}

