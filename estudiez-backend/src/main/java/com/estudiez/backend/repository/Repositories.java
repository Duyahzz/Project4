package com.estudiez.backend.repository;

import com.estudiez.backend.entity.*;
import com.estudiez.backend.entity.embeddable.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository interface RoleRepo extends JpaRepository<Role, Integer> { Optional<Role> findByCode(String code); }

@Repository interface UserRepo extends JpaRepository<User, UUID> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    List<User> findByRoleId(Integer roleId);
    boolean existsByUsername(String username);
}

@Repository interface TeacherRepo extends JpaRepository<Teacher, UUID> {
    Optional<Teacher> findByUserId(UUID userId);
    Optional<Teacher> findByEmployeeCode(String employeeCode);
    List<Teacher> findBySubjectId(Integer subjectId);
}

@Repository interface StudentRepo extends JpaRepository<Student, UUID> {
    Optional<Student> findByUserId(UUID userId);
    Optional<Student> findByStudentCode(String studentCode);
    List<Student> findByStatus(String status);
}

@Repository interface ParentRepo extends JpaRepository<Parent, UUID> {
    Optional<Parent> findByUserId(UUID userId);
}

@Repository interface GradeRepo extends JpaRepository<Grade, Integer> {
    Optional<Grade> findByCode(String code);
}

@Repository interface SubjectRepo extends JpaRepository<Subject, Integer> {
    Optional<Subject> findByCode(String code);
    List<Subject> findByIsActive(Boolean isActive);
}

@Repository interface AssessmentTypeRepo extends JpaRepository<AssessmentType, Integer> {
    Optional<AssessmentType> findByCode(String code);
}

@Repository interface SchoolContactRepo extends JpaRepository<SchoolContact, Integer> {
    List<SchoolContact> findByIsActive(Boolean isActive);
}

@Repository interface SchoolYearRepo extends JpaRepository<SchoolYear, Integer> {
    Optional<SchoolYear> findByIsCurrent(Boolean isCurrent);
}

@Repository interface SemesterRepo extends JpaRepository<Semester, Integer> {
    List<Semester> findBySchoolYearId(Integer schoolYearId);
}

@Repository interface SchoolClassRepo extends JpaRepository<SchoolClass, Integer> {
    List<SchoolClass> findBySchoolYearId(Integer schoolYearId);
    List<SchoolClass> findByIsActive(Boolean isActive);
}

@Repository interface ClassEnrollmentRepo extends JpaRepository<ClassEnrollment, Integer> {
    List<ClassEnrollment> findByClassId(Integer classId);
    List<ClassEnrollment> findByStudentId(UUID studentId);
    List<ClassEnrollment> findByStudentIdAndStatus(UUID studentId, String status);
}

@Repository interface TeacherClassAssignmentRepo extends JpaRepository<TeacherClassAssignment, Integer> {
    List<TeacherClassAssignment> findByTeacherId(UUID teacherId);
    List<TeacherClassAssignment> findByClassIdAndSchoolYearId(Integer classId, Integer schoolYearId);
}

@Repository interface StudentParentLinkRepo extends JpaRepository<StudentParentLink, StudentParentLinkId> {
    List<StudentParentLink> findByIdStudentId(UUID studentId);
    List<StudentParentLink> findByIdParentId(UUID parentId);
}

@Repository interface TimetableSlotRepo extends JpaRepository<TimetableSlot, Integer> {
    List<TimetableSlot> findByClassIdAndSemesterId(Integer classId, Integer semesterId);
    List<TimetableSlot> findByTeacherId(UUID teacherId);
}

@Repository interface LessonSessionRepo extends JpaRepository<LessonSession, Integer> {
    List<LessonSession> findByClassId(Integer classId);
    List<LessonSession> findByTeacherId(UUID teacherId);
    List<LessonSession> findByClassIdAndStatus(Integer classId, String status);
}

@Repository interface AttendanceRecordRepo extends JpaRepository<AttendanceRecord, Integer> {
    List<AttendanceRecord> findByLessonSessionId(Integer lessonSessionId);
    List<AttendanceRecord> findByStudentId(UUID studentId);
    Optional<AttendanceRecord> findByLessonSessionIdAndStudentId(Integer lessonSessionId, UUID studentId);
}

@Repository interface AssessmentRepo extends JpaRepository<Assessment, Integer> {
    List<Assessment> findByClassId(Integer classId);
    List<Assessment> findBySubjectIdAndSemesterId(Integer subjectId, Integer semesterId);
    List<Assessment> findByTeacherId(UUID teacherId);
}

@Repository interface StudentMarkRepo extends JpaRepository<StudentMark, Integer> {
    List<StudentMark> findByStudentId(UUID studentId);
    List<StudentMark> findByAssessmentId(Integer assessmentId);
    Optional<StudentMark> findByAssessmentIdAndStudentId(Integer assessmentId, UUID studentId);
}

@Repository interface SkillAreaRepo extends JpaRepository<SkillArea, Integer> {
    List<SkillArea> findBySubjectId(Integer subjectId);
}

@Repository interface AssessmentSkillEvaluationRepo extends JpaRepository<AssessmentSkillEvaluation, Integer> {
    List<AssessmentSkillEvaluation> findByStudentMarkId(Integer studentMarkId);
}

@Repository interface StudyResourceRepo extends JpaRepository<StudyResource, Integer> {
    List<StudyResource> findBySubjectId(Integer subjectId);
    List<StudyResource> findByClassId(Integer classId);
    List<StudyResource> findBySubjectIdAndVisibility(Integer subjectId, String visibility);
}

@Repository interface AiKnowledgeChunkRepo extends JpaRepository<AiKnowledgeChunk, Integer> {
    List<AiKnowledgeChunk> findByResourceIdOrderByChunkIndex(Integer resourceId);
}

@Repository interface AiRecommendationRunRepo extends JpaRepository<AiRecommendationRun, Integer> {
    List<AiRecommendationRun> findByStudentId(UUID studentId);
    List<AiRecommendationRun> findByStudentIdAndSubjectId(UUID studentId, Integer subjectId);
}

@Repository interface LearningPathRepo extends JpaRepository<LearningPath, Integer> {
    List<LearningPath> findByStudentId(UUID studentId);
    List<LearningPath> findByStudentIdAndStatus(UUID studentId, String status);
}

@Repository interface LearningPathItemRepo extends JpaRepository<LearningPathItem, Integer> {
    List<LearningPathItem> findByLearningPathIdOrderByPriority(Integer learningPathId);
}

@Repository interface ChatGroupRepo extends JpaRepository<ChatGroup, Integer> {
    List<ChatGroup> findByClassId(Integer classId);
}

@Repository interface ChatGroupMemberRepo extends JpaRepository<ChatGroupMember, ChatGroupMemberId> {
    List<ChatGroupMember> findByIdChatGroupId(Integer chatGroupId);
    List<ChatGroupMember> findByIdUserId(UUID userId);
}

@Repository interface ChatMessageRepo extends JpaRepository<ChatMessage, Integer> {
    List<ChatMessage> findByChatGroupIdAndDeletedAtIsNullOrderByCreatedAtDesc(Integer chatGroupId);
}

@Repository interface NotificationRepo extends JpaRepository<Notification, Integer> {
    List<Notification> findBySenderUserId(UUID senderUserId);
}

@Repository interface NotificationRecipientRepo extends JpaRepository<NotificationRecipient, NotificationRecipientId> {
    List<NotificationRecipient> findByIdUserId(UUID userId);
    List<NotificationRecipient> findByIdUserIdAndReadAtIsNull(UUID userId);
}

@Repository interface FeedbackTicketRepo extends JpaRepository<FeedbackTicket, Integer> {
    List<FeedbackTicket> findByStatus(String status);
    List<FeedbackTicket> findBySenderUserId(UUID senderUserId);
}

@Repository interface NewsPostRepo extends JpaRepository<NewsPost, Integer> {
    List<NewsPost> findByStatus(String status);
    Optional<NewsPost> findBySlug(String slug);
}

