package com.estudiez.backend.controller.dto;

/**
 * Request body for POST /api/auth/login
 */
public record LoginRequest(String username, String password) {}

