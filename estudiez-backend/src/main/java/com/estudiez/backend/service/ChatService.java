package com.estudiez.backend.service;

import com.estudiez.backend.entity.ChatGroup;
import com.estudiez.backend.entity.ChatMessage;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.ChatGroupRepository;
import com.estudiez.backend.repository.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatGroupRepository chatGroupRepo;
    private final ChatMessageRepository chatMessageRepo;

    public List<ChatGroup> findAllGroups() { return chatGroupRepo.findAll(); }

    public List<ChatGroup> findGroupsByClass(Integer classId) {
        return chatGroupRepo.findAll().stream()
                .filter(g -> classId.equals(g.getClassId()))
                .toList();
    }

    public ChatGroup findGroupById(Integer id) {
        return chatGroupRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ChatGroup", id));
    }

    public ChatGroup createGroup(ChatGroup group) { return chatGroupRepo.save(group); }

    public List<ChatMessage> findMessagesByGroup(Integer groupId) {
        return chatMessageRepo.findAll().stream()
                .filter(m -> groupId.equals(m.getChatGroupId()) && m.getDeletedAt() == null)
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                .toList();
    }

    public ChatMessage sendMessage(ChatMessage message) { return chatMessageRepo.save(message); }

    public void deleteMessage(Integer id) {
        ChatMessage msg = chatMessageRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ChatMessage", id));
        msg.setDeletedAt(java.time.LocalDateTime.now());
        chatMessageRepo.save(msg);
    }
}
