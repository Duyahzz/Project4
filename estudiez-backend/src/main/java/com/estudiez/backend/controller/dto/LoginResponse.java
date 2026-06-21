package com.estudiez.backend.controller.dto;

import java.util.UUID;

/**
 * Response body for POST /api/auth/login
 */
public record LoginResponse(
        UUID userId,
        String username,
        String fullName,
        String email,
        String phone,
        String avatarUrl,
        String role,    // e.g. "ADMIN", "TEACHER", "STUDENT", "PARENT"
        Boolean isActive
) {}

