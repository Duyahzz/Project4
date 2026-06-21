package com.estudiez.backend.service;

import com.estudiez.backend.controller.dto.LoginResponse;
import com.estudiez.backend.entity.Role;
import com.estudiez.backend.entity.User;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.RoleRepository;
import com.estudiez.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepo;
    private final PasswordEncoder passwordEncoder;
    private final RoleRepository roleRepo;

    public List<User> findAll() { return userRepo.findAll(); }

    public User findById(UUID id) {
        return userRepo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User", id));
    }

    public User findByUsername(String username) {
        return userRepo.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User not found: " + username));
    }

    public User create(User user) {
        if (userRepo.existsByUsername(user.getUsername()))
            throw new IllegalArgumentException("Username already exists: " + user.getUsername());
        user.setPasswordHash(passwordEncoder.encode(user.getPasswordHash()));
        return userRepo.save(user);
    }

    public User update(UUID id, User updated) {
        User user = findById(id);
        user.setFullName(updated.getFullName());
        user.setEmail(updated.getEmail());
        user.setPhone(updated.getPhone());
        user.setAvatarUrl(updated.getAvatarUrl());
        user.setIsActive(updated.getIsActive());
        return userRepo.save(user);
    }

    public void delete(UUID id) {
        if (!userRepo.existsById(id)) throw new ResourceNotFoundException("User", id);
        userRepo.deleteById(id);
    }

    /**
     * Validates credentials and returns a LoginResponse.
     * Throws IllegalArgumentException if username not found or password is wrong.
     * Throws IllegalStateException if the account is inactive.
     */
    public LoginResponse login(String username, String password) {
        User user = userRepo.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("Invalid username or password"));

        if (!passwordEncoder.matches(password, user.getPasswordHash()))
            throw new IllegalArgumentException("Invalid username or password");

        if (!user.getIsActive())
            throw new IllegalStateException("Account is disabled");

        // Update last login timestamp
        user.setLastLoginAt(LocalDateTime.now());
        userRepo.save(user);

        String roleCode = roleRepo.findById(user.getRoleId())
                .map(Role::getCode)
                .orElse("UNKNOWN");

        return new LoginResponse(
                user.getUserId(),
                user.getUsername(),
                user.getFullName(),
                user.getEmail(),
                user.getPhone(),
                user.getAvatarUrl(),
                roleCode,
                user.getIsActive()
        );
    }

    /**
     * Changes the password for the given user.
     * Throws IllegalArgumentException if the current password is wrong.
     */
    public void changePassword(UUID userId, String currentPassword, String newPassword) {
        User user = findById(userId);
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash()))
            throw new IllegalArgumentException("Current password is incorrect");
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepo.save(user);
    }
}



