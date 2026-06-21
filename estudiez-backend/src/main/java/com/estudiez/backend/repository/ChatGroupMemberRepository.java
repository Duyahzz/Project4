package com.estudiez.backend.repository;

import com.estudiez.backend.entity.ChatGroupMember;
import com.estudiez.backend.entity.embeddable.ChatGroupMemberId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ChatGroupMemberRepository extends JpaRepository<ChatGroupMember, ChatGroupMemberId> {
    List<ChatGroupMember> findByIdChatGroupId(Integer chatGroupId);
    List<ChatGroupMember> findByIdUserId(UUID userId);
}

