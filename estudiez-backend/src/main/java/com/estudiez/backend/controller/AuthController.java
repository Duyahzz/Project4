package com.estudiez.backend.controller;

import com.estudiez.backend.controller.dto.LoginRequest;
import com.estudiez.backend.controller.dto.LoginResponse;
import com.estudiez.backend.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@Tag(name = "Auth", description = "Login and authentication")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @Operation(
        summary = "Login",
        description = """
            Validates username + password and returns the user profile with their role.

            **Test accounts:**
            | Username | Password | Role |
            |---|---|---|
            | admin | Admin@123 | ADMIN |
            | teacher.math | Teacher@123 | TEACHER |
            | teacher.lit | Teacher@123 | TEACHER |
            | teacher.eng | Teacher@123 | TEACHER |
            | bao.pq | Student@123 | STUDENT |
            | mai.nt | Student@123 | STUDENT |
            | duc.tv | Student@123 | STUDENT |
            | hoa.lt | Student@123 | STUDENT |
            | khoa.vm | Student@123 | STUDENT |
            | parent.bao | Parent@123 | PARENT |
            | parent.mai | Parent@123 | PARENT |
            """
    )
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            LoginResponse response = userService.login(request.username(), request.password());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ErrorBody(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ErrorBody(e.getMessage()));
        }
    }

    @Operation(summary = "Change password", description = "Changes the password for the given user after verifying the current password.")
    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            userService.changePassword(
                UUID.fromString(request.userId()),
                request.currentPassword(),
                request.newPassword()
            );
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(new ErrorBody(e.getMessage()));
        }
    }

    record ChangePasswordRequest(String userId, String currentPassword, String newPassword) {}

    record ErrorBody(String message) {}
}

