package com.estudiez.backend.controller.dto;

/**
 * Request body for linking a parent to a student.
 * Use {@code childEmail} to identify the student by their account email.
 * Use {@code studentId} to identify the student directly by UUID.
 * At least one of {@code childEmail} or {@code studentId} must be provided.
 */
public record LinkStudentRequest(
        String childEmail,
        String studentId,
        String relationship,
        Boolean isPrimaryContact
) {}

