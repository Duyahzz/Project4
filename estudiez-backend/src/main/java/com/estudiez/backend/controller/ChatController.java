package com.estudiez.backend.controller;

import com.estudiez.backend.entity.ChatGroup;
import com.estudiez.backend.entity.ChatMessage;
import com.estudiez.backend.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    // ── Groups ──────────────────────────────────────────────────────────────

    @GetMapping("/groups")
    public List<ChatGroup> getGroups(@RequestParam(required = false) Integer classId) {
        return classId != null ? chatService.findGroupsByClass(classId) : chatService.findAllGroups();
    }

    @GetMapping("/groups/{id}")
    public ChatGroup getGroupById(@PathVariable Integer id) { return chatService.findGroupById(id); }

    @PostMapping("/groups")
    public ResponseEntity<ChatGroup> createGroup(@RequestBody ChatGroup group) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chatService.createGroup(group));
    }

    // ── Messages ────────────────────────────────────────────────────────────

    @GetMapping("/groups/{id}/messages")
    public List<ChatMessage> getMessages(@PathVariable Integer id) {
        return chatService.findMessagesByGroup(id);
    }

    @PostMapping("/messages")
    public ResponseEntity<ChatMessage> sendMessage(@RequestBody ChatMessage message) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chatService.sendMessage(message));
    }

    @DeleteMapping("/messages/{id}")
    public ResponseEntity<Void> deleteMessage(@PathVariable Integer id) {
        chatService.deleteMessage(id);
        return ResponseEntity.noContent().build();
    }
}
