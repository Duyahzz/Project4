-- =============================================================
--  eStudiez — Full Database Reset + Seed
--  Drops eStudentDB, recreates schema, inserts comprehensive demo data.
--
--  Run: sqlcmd -S localhost,1433 -U sa -P "YourStrong@Passw0rd" -i doc\seed-data.sql
--
--  Credentials after seed:
--    admin          / Admin@123
--    teacher.math   / Teacher@123   (all 10 teachers)
--    bao.pq         / Student@123   (all 16 students)
--    parent.bao     / Parent@123    (all 16 parents)
--
--  Spring Boot DataInitializer is automatically skipped on startup
--  because all tables will already have data.
-- =============================================================

-- ══════════════════════════════════════════════════════════════
--  SECTION 1 — DROP AND RECREATE DATABASE
-- ══════════════════════════════════════════════════════════════
USE master;
GO

IF DB_ID(N'eStudentDB') IS NOT NULL
BEGIN
    ALTER DATABASE eStudentDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE eStudentDB;
END
GO

CREATE DATABASE eStudentDB;
GO

USE eStudentDB;
GO

-- ══════════════════════════════════════════════════════════════
--  SECTION 2 — SCHEMA
-- ══════════════════════════════════════════════════════════════

-- ── Lookup / Reference ─────────────────────────────────────────
CREATE TABLE Roles (
    RoleId INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Code   NVARCHAR(30)  NOT NULL UNIQUE,
    Name   NVARCHAR(100) NOT NULL
);

CREATE TABLE Grades (
    GradeId INT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Code    NVARCHAR(10) NOT NULL UNIQUE,
    Name    NVARCHAR(50) NOT NULL
);

CREATE TABLE AssessmentTypes (
    AssessmentTypeId INT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Code             NVARCHAR(30) NOT NULL UNIQUE,
    Name             NVARCHAR(100) NOT NULL,
    DefaultWeight    DECIMAL(5,2) NOT NULL DEFAULT 1
);

CREATE TABLE SchoolContacts (
    SchoolContactId INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name            NVARCHAR(150) NOT NULL,
    Email           NVARCHAR(150) NULL,
    Phone           NVARCHAR(30)  NULL,
    Address         NVARCHAR(MAX) NULL,
    WorkingHours    NVARCHAR(255) NULL,
    IsActive        BIT           NOT NULL DEFAULT 1
);

-- ── Core Entities ──────────────────────────────────────────────
CREATE TABLE Users (
    UserId       UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    RoleId       INT              NOT NULL,
    Username     NVARCHAR(80)     NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255)    NOT NULL,
    FullName     NVARCHAR(150)    NOT NULL,
    Email        NVARCHAR(150)    NULL,
    Phone        NVARCHAR(30)     NULL,
    AvatarUrl    NVARCHAR(500)    NULL,
    IsActive     BIT              NOT NULL DEFAULT 1,
    LastLoginAt  DATETIME2(7)     NULL,
    CreatedAt    DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE Subjects (
    SubjectId   INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Code        NVARCHAR(30)  NOT NULL UNIQUE,
    Name        NVARCHAR(120) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    IsActive    BIT           NOT NULL DEFAULT 1
);

CREATE TABLE Teachers (
    TeacherId     UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId        UNIQUEIDENTIFIER NOT NULL UNIQUE,
    EmployeeCode  NVARCHAR(50)     NOT NULL UNIQUE,
    SubjectId     INT              NOT NULL,
    Qualification NVARCHAR(150)    NULL,
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE Students (
    StudentId     UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId        UNIQUEIDENTIFIER NOT NULL UNIQUE,
    StudentCode   NVARCHAR(50)     NOT NULL UNIQUE,
    DateOfBirth   DATE             NULL,
    Gender        NVARCHAR(20)     NULL,
    Address       NVARCHAR(MAX)    NULL,
    AdmissionDate DATE             NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status        NVARCHAR(30)     NOT NULL DEFAULT 'ACTIVE',
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Students_Status CHECK (Status IN ('ACTIVE','TRANSFERRED','GRADUATED','SUSPENDED'))
);

CREATE TABLE Parents (
    ParentId   UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
    UserId     UNIQUEIDENTIFIER NOT NULL UNIQUE,
    Occupation NVARCHAR(120)    NULL,
    Address    NVARCHAR(MAX)    NULL,
    CreatedAt  DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME()
);

-- ── School Structure ───────────────────────────────────────────
CREATE TABLE SchoolYears (
    SchoolYearId INT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name         NVARCHAR(30) NOT NULL UNIQUE,
    StartDate    DATE         NOT NULL,
    EndDate      DATE         NOT NULL,
    IsCurrent    BIT          NOT NULL DEFAULT 0,
    CONSTRAINT CK_SchoolYears_Date CHECK (StartDate < EndDate)
);

CREATE TABLE Semesters (
    SemesterId   INT          IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SchoolYearId INT          NOT NULL,
    Name         NVARCHAR(50) NOT NULL,
    StartDate    DATE         NOT NULL,
    EndDate      DATE         NOT NULL,
    CONSTRAINT UQ_Semesters       UNIQUE (SchoolYearId, Name),
    CONSTRAINT CK_Semesters_Date  CHECK  (StartDate < EndDate)
);

CREATE TABLE Classes (
    ClassId           INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SchoolYearId      INT              NOT NULL,
    GradeId           INT              NOT NULL,
    Name              NVARCHAR(50)     NOT NULL,
    HomeroomTeacherId UNIQUEIDENTIFIER NULL,
    TrainingProgram   NVARCHAR(30)     NOT NULL DEFAULT 'REGULAR',
    Room              NVARCHAR(50)     NULL,
    IsActive          BIT              NOT NULL DEFAULT 1,
    CONSTRAINT UQ_Classes          UNIQUE (SchoolYearId, Name, TrainingProgram),
    CONSTRAINT CK_Classes_Training CHECK  (TrainingProgram IN ('REGULAR','REVISION'))
);

CREATE TABLE ClassEnrollments (
    EnrollmentId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClassId      INT              NOT NULL,
    StudentId    UNIQUEIDENTIFIER NOT NULL,
    EnrolledAt   DATE             NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    LeftAt       DATE             NULL,
    Status       NVARCHAR(30)     NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT UQ_ClassEnrollments        UNIQUE (ClassId, StudentId),
    CONSTRAINT CK_ClassEnrollments_Date   CHECK  (LeftAt IS NULL OR LeftAt >= EnrolledAt),
    CONSTRAINT CK_ClassEnrollments_Status CHECK  (Status IN ('ACTIVE','LEFT','COMPLETED'))
);

CREATE TABLE StudentParentLinks (
    StudentId        UNIQUEIDENTIFIER NOT NULL,
    ParentId         UNIQUEIDENTIFIER NOT NULL,
    Relationship     NVARCHAR(50)     NOT NULL,
    IsPrimaryContact BIT              NOT NULL DEFAULT 0,
    PRIMARY KEY (StudentId, ParentId)
);

CREATE TABLE TeacherClassAssignments (
    AssignmentId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TeacherId    UNIQUEIDENTIFIER NOT NULL,
    ClassId      INT              NOT NULL,
    SubjectId    INT              NOT NULL,
    SchoolYearId INT              NOT NULL,
    CONSTRAINT UQ_TeacherClassAssignments UNIQUE (TeacherId, ClassId, SubjectId, SchoolYearId)
);

-- ── Timetable & Lessons ────────────────────────────────────────
CREATE TABLE TimetableSlots (
    TimetableSlotId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClassId         INT              NOT NULL,
    SubjectId       INT              NOT NULL,
    TeacherId       UNIQUEIDENTIFIER NOT NULL,
    SemesterId      INT              NOT NULL,
    DayOfWeek       TINYINT          NOT NULL,
    PeriodNo        TINYINT          NOT NULL,
    StartTime       TIME(7)          NOT NULL,
    EndTime         TIME(7)          NOT NULL,
    Room            NVARCHAR(50)     NULL,
    EffectiveFrom   DATE             NOT NULL,
    EffectiveTo     DATE             NULL,
    CONSTRAINT CK_Timetable_Day    CHECK (DayOfWeek >= 1 AND DayOfWeek <= 7),
    CONSTRAINT CK_Timetable_Period CHECK (PeriodNo > 0),
    CONSTRAINT CK_Timetable_Time   CHECK (StartTime < EndTime)
);

CREATE TABLE LessonSessions (
    LessonSessionId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TimetableSlotId INT              NULL,
    ClassId         INT              NOT NULL,
    SubjectId       INT              NOT NULL,
    TeacherId       UNIQUEIDENTIFIER NOT NULL,
    SessionDate     DATE             NOT NULL,
    PeriodNo        TINYINT          NOT NULL,
    Room            NVARCHAR(50)     NULL,
    Topic           NVARCHAR(255)    NULL,
    Status          NVARCHAR(30)     NOT NULL DEFAULT 'SCHEDULED',
    CreatedAt       DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_LessonSessions_Status CHECK (Status IN ('SCHEDULED','COMPLETED','CANCELLED'))
);

CREATE TABLE AttendanceRecords (
    AttendanceId    INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LessonSessionId INT              NOT NULL,
    StudentId       UNIQUEIDENTIFIER NOT NULL,
    Status          NVARCHAR(30)     NOT NULL,
    Note            NVARCHAR(MAX)    NULL,
    RecordedBy      UNIQUEIDENTIFIER NOT NULL,
    RecordedAt      DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_Attendance        UNIQUE (LessonSessionId, StudentId),
    CONSTRAINT CK_Attendance_Status CHECK  (Status IN ('PRESENT','ABSENT','LATE','EXCUSED'))
);

-- ── Assessments & Marks ────────────────────────────────────────
CREATE TABLE Assessments (
    AssessmentId     INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClassId          INT              NOT NULL,
    SubjectId        INT              NOT NULL,
    TeacherId        UNIQUEIDENTIFIER NOT NULL,
    SemesterId       INT              NOT NULL,
    AssessmentTypeId INT              NOT NULL,
    Title            NVARCHAR(255)    NOT NULL,
    AssessmentDate   DATE             NOT NULL,
    MaxScore         DECIMAL(5,2)     NOT NULL DEFAULT 10,
    Weight           DECIMAL(5,2)     NOT NULL DEFAULT 1,
    Description      NVARCHAR(MAX)    NULL,
    Status           NVARCHAR(30)     NOT NULL DEFAULT 'SCHEDULED',
    CreatedAt        DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Assessments_MaxScore CHECK (MaxScore > 0),
    CONSTRAINT CK_Assessments_Weight   CHECK (Weight  > 0),
    CONSTRAINT CK_Assessments_Status   CHECK (Status  IN ('SCHEDULED','COMPLETED','CANCELLED'))
);

CREATE TABLE StudentMarks (
    StudentMarkId  INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AssessmentId   INT              NOT NULL,
    StudentId      UNIQUEIDENTIFIER NOT NULL,
    Score          DECIMAL(5,2)     NOT NULL,
    TeacherComment NVARCHAR(MAX)    NULL,
    Remark         NVARCHAR(MAX)    NULL,
    GradedBy       UNIQUEIDENTIFIER NOT NULL,
    GradedAt       DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_StudentMarks       UNIQUE (AssessmentId, StudentId),
    CONSTRAINT CK_StudentMarks_Score CHECK  (Score >= 0)
);

CREATE TABLE SkillAreas (
    SkillAreaId INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SubjectId   INT           NOT NULL,
    Code        NVARCHAR(50)  NOT NULL,
    Name        NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CONSTRAINT UQ_SkillAreas UNIQUE (SubjectId, Code)
);

CREATE TABLE AssessmentSkillEvaluations (
    EvaluationId    INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StudentMarkId   INT           NOT NULL,
    SkillAreaId     INT           NOT NULL,
    MasteryLevel    DECIMAL(5,2)  NULL,
    Strengths       NVARCHAR(MAX) NULL,
    Weaknesses      NVARCHAR(MAX) NULL,
    TeacherFeedback NVARCHAR(MAX) NULL,
    Evidence        NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME2(7)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_AssessmentSkillEvaluations  UNIQUE (StudentMarkId, SkillAreaId),
    CONSTRAINT CK_Evaluations_Mastery         CHECK  (MasteryLevel IS NULL OR (MasteryLevel >= 0 AND MasteryLevel <= 100)),
    CONSTRAINT CK_Evaluations_EvidenceJson    CHECK  (Evidence IS NULL OR ISJSON(Evidence) = 1)
);

-- ── Study Resources & AI ───────────────────────────────────────
CREATE TABLE StudyResources (
    ResourceId   INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SubjectId    INT              NOT NULL,
    ClassId      INT              NULL,
    UploadedBy   UNIQUEIDENTIFIER NOT NULL,
    Title        NVARCHAR(255)    NOT NULL,
    Description  NVARCHAR(MAX)    NULL,
    ResourceType NVARCHAR(30)     NOT NULL,
    FileUrl      NVARCHAR(500)    NOT NULL,
    ThumbnailUrl NVARCHAR(500)    NULL,
    Visibility   NVARCHAR(30)     NOT NULL DEFAULT 'CLASS_ONLY',
    CreatedAt    DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Resources_Type       CHECK (ResourceType IN ('IMAGE','VIDEO','PDF','DOCUMENT','LINK')),
    CONSTRAINT CK_Resources_Visibility CHECK (Visibility   IN ('CLASS_ONLY','SCHOOL','TEACHER_ONLY'))
);

CREATE TABLE AiKnowledgeChunks (
    AiKnowledgeChunkId INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ResourceId         INT           NULL,
    ChunkIndex         INT           NOT NULL,
    Content            NVARCHAR(MAX) NOT NULL,
    Metadata           NVARCHAR(MAX) NULL,
    CreatedAt          DATETIME2(7)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_AiKnowledgeChunks         UNIQUE (ResourceId, ChunkIndex),
    CONSTRAINT CK_AiKnowledgeChunks_MetaJson CHECK  (Metadata IS NULL OR ISJSON(Metadata) = 1)
);

CREATE TABLE AiRecommendationRuns (
    AiRunId       INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StudentId     UNIQUEIDENTIFIER NOT NULL,
    SubjectId     INT              NULL,
    SourceType    NVARCHAR(50)     NOT NULL,
    SourceId      NVARCHAR(100)    NULL,
    ModelName     NVARCHAR(100)    NULL,
    InputSnapshot NVARCHAR(MAX)    NOT NULL,
    OutputSummary NVARCHAR(MAX)    NULL,
    Confidence    DECIMAL(5,2)     NULL,
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_AiRuns_Confidence CHECK (Confidence IS NULL OR (Confidence >= 0 AND Confidence <= 100)),
    CONSTRAINT CK_AiRuns_InputJson  CHECK (ISJSON(InputSnapshot) = 1)
);

-- ── Learning Paths ─────────────────────────────────────────────
CREATE TABLE LearningPaths (
    LearningPathId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StudentId      UNIQUEIDENTIFIER NOT NULL,
    SubjectId      INT              NOT NULL,
    AiRunId        INT              NULL,
    Title          NVARCHAR(255)    NOT NULL,
    Goal           NVARCHAR(MAX)    NOT NULL,
    Status         NVARCHAR(30)     NOT NULL DEFAULT 'ACTIVE',
    StartDate      DATE             NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    TargetEndDate  DATE             NULL,
    CreatedAt      DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_LearningPaths_Status CHECK (Status IN ('ACTIVE','COMPLETED','PAUSED','CANCELLED'))
);

CREATE TABLE LearningPathItems (
    LearningPathItemId INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LearningPathId     INT           NOT NULL,
    SkillAreaId        INT           NULL,
    ResourceId         INT           NULL,
    Title              NVARCHAR(255) NOT NULL,
    Description        NVARCHAR(MAX) NULL,
    Priority           TINYINT       NOT NULL DEFAULT 3,
    DueDate            DATE          NULL,
    Status             NVARCHAR(30)  NOT NULL DEFAULT 'TODO',
    CompletedAt        DATETIME2(7)  NULL,
    CONSTRAINT CK_LearningPathItems_Priority CHECK (Priority >= 1 AND Priority <= 5),
    CONSTRAINT CK_LearningPathItems_Status   CHECK  (Status IN ('TODO','IN_PROGRESS','DONE','SKIPPED'))
);

-- ── Communication ──────────────────────────────────────────────
CREATE TABLE ChatGroups (
    ChatGroupId  INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClassId      INT           NOT NULL,
    SchoolYearId INT           NOT NULL,
    GroupType    NVARCHAR(30)  NOT NULL,
    Name         NVARCHAR(150) NOT NULL,
    CreatedAt    DATETIME2(7)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_ChatGroups      UNIQUE (ClassId, SchoolYearId, GroupType),
    CONSTRAINT CK_ChatGroups_Type CHECK  (GroupType IN ('STUDENT_TEACHER','PARENT_TEACHER'))
);

CREATE TABLE ChatGroupMembers (
    ChatGroupId INT              NOT NULL,
    UserId      UNIQUEIDENTIFIER NOT NULL,
    JoinedAt    DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    LeftAt      DATETIME2(7)     NULL,
    PRIMARY KEY (ChatGroupId, UserId)
);

CREATE TABLE ChatMessages (
    ChatMessageId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ChatGroupId   INT              NOT NULL,
    SenderUserId  UNIQUEIDENTIFIER NOT NULL,
    MessageText   NVARCHAR(MAX)    NULL,
    AttachmentUrl NVARCHAR(500)    NULL,
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    DeletedAt     DATETIME2(7)     NULL,
    CONSTRAINT CK_ChatMessages_Content CHECK (MessageText IS NOT NULL OR AttachmentUrl IS NOT NULL)
);

CREATE TABLE Notifications (
    NotificationId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SenderUserId   UNIQUEIDENTIFIER NOT NULL,
    Title          NVARCHAR(255)    NOT NULL,
    Content        NVARCHAR(MAX)    NOT NULL,
    Category       NVARCHAR(50)     NOT NULL,
    TargetType     NVARCHAR(30)     NOT NULL,
    TargetId       NVARCHAR(100)    NULL,
    CreatedAt      DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Notifications_Target CHECK (TargetType IN ('ALL','ROLE','CLASS','STUDENT','PARENT','TEACHER'))
);

CREATE TABLE NotificationRecipients (
    NotificationId INT              NOT NULL,
    UserId         UNIQUEIDENTIFIER NOT NULL,
    ReadAt         DATETIME2(7)     NULL,
    PRIMARY KEY (NotificationId, UserId)
);

CREATE TABLE FeedbackTickets (
    FeedbackTicketId INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SenderUserId     UNIQUEIDENTIFIER NOT NULL,
    RelatedStudentId UNIQUEIDENTIFIER NULL,
    Category         NVARCHAR(50)     NOT NULL,
    Subject          NVARCHAR(255)    NOT NULL,
    Content          NVARCHAR(MAX)    NOT NULL,
    Status           NVARCHAR(30)     NOT NULL DEFAULT 'OPEN',
    HandledBy        UNIQUEIDENTIFIER NULL,
    HandledAt        DATETIME2(7)     NULL,
    AdminResponse    NVARCHAR(MAX)    NULL,
    CreatedAt        DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Feedback_Status CHECK (Status IN ('OPEN','IN_PROGRESS','RESOLVED','CLOSED'))
);

-- ── News ───────────────────────────────────────────────────────
CREATE TABLE NewsPosts (
    NewsPostId    INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AuthorUserId  UNIQUEIDENTIFIER NOT NULL,
    Category      NVARCHAR(50)     NOT NULL DEFAULT 'GENERAL',
    Title         NVARCHAR(255)    NOT NULL,
    Slug          NVARCHAR(255)    NOT NULL UNIQUE,
    Content       NVARCHAR(MAX)    NOT NULL,
    CoverImageUrl NVARCHAR(500)    NULL,
    Status        NVARCHAR(30)     NOT NULL DEFAULT 'DRAFT',
    PublishedAt   DATETIME2(7)     NULL,
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_News_Status CHECK (Status IN ('DRAFT','PUBLISHED','ARCHIVED'))
);

-- ── Registration Requests ──────────────────────────────────────
CREATE TABLE RegistrationRequests (
    RequestId     INT              IDENTITY(1,1) NOT NULL PRIMARY KEY,
    FullName      NVARCHAR(150)    NOT NULL,
    Email         NVARCHAR(150)    NOT NULL,
    Phone         NVARCHAR(30)     NULL,
    RoleRequested NVARCHAR(30)     NOT NULL,
    Message       NVARCHAR(MAX)    NULL,
    Status        NVARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    ReviewedBy    UNIQUEIDENTIFIER NULL,
    ReviewNotes   NVARCHAR(MAX)    NULL,
    ReviewedAt    DATETIME2(7)     NULL,
    CreatedAt     DATETIME2(7)     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_RegReq_Role   CHECK (RoleRequested IN ('student','parent','teacher')),
    CONSTRAINT CK_RegReq_Status CHECK (Status        IN ('PENDING','APPROVED','REJECTED'))
);

-- ── Indexes ────────────────────────────────────────────────────
CREATE INDEX IX_Users_RoleId             ON Users                (RoleId);
CREATE INDEX IX_Classes_YearGrade        ON Classes              (SchoolYearId, GradeId);
CREATE INDEX IX_ClassEnrollments_Student ON ClassEnrollments     (StudentId);
CREATE INDEX IX_Lessons_ClassDate        ON LessonSessions       (ClassId, SessionDate);
CREATE INDEX IX_Attendance_Student       ON AttendanceRecords    (StudentId);
CREATE INDEX IX_StudentMarks_Student     ON StudentMarks         (StudentId);
CREATE INDEX IX_Resources_SubjectClass   ON StudyResources       (SubjectId, ClassId);
CREATE INDEX IX_AiRuns_StudentSubject    ON AiRecommendationRuns (StudentId, SubjectId);
CREATE INDEX IX_Timetable_ClassDay       ON TimetableSlots       (ClassId, DayOfWeek);
CREATE INDEX IX_RegReq_Status            ON RegistrationRequests (Status);
CREATE INDEX IX_News_Category            ON NewsPosts            (Category);

-- ── Foreign Keys ───────────────────────────────────────────────
ALTER TABLE Users                    ADD CONSTRAINT FK_Users_Roles                  FOREIGN KEY (RoleId)              REFERENCES Roles                (RoleId);
ALTER TABLE Teachers                 ADD CONSTRAINT FK_Teachers_Users               FOREIGN KEY (UserId)              REFERENCES Users                (UserId);
ALTER TABLE Teachers                 ADD CONSTRAINT FK_Teachers_Subjects            FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE Students                 ADD CONSTRAINT FK_Students_Users               FOREIGN KEY (UserId)              REFERENCES Users                (UserId);
ALTER TABLE Parents                  ADD CONSTRAINT FK_Parents_Users                FOREIGN KEY (UserId)              REFERENCES Users                (UserId);
ALTER TABLE StudentParentLinks       ADD CONSTRAINT FK_SPL_Students                 FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE StudentParentLinks       ADD CONSTRAINT FK_SPL_Parents                  FOREIGN KEY (ParentId)            REFERENCES Parents              (ParentId);
ALTER TABLE Semesters                ADD CONSTRAINT FK_Semesters_SchoolYears        FOREIGN KEY (SchoolYearId)        REFERENCES SchoolYears          (SchoolYearId);
ALTER TABLE Classes                  ADD CONSTRAINT FK_Classes_SchoolYears          FOREIGN KEY (SchoolYearId)        REFERENCES SchoolYears          (SchoolYearId);
ALTER TABLE Classes                  ADD CONSTRAINT FK_Classes_Grades               FOREIGN KEY (GradeId)             REFERENCES Grades               (GradeId);
ALTER TABLE Classes                  ADD CONSTRAINT FK_Classes_HomeroomTeacher      FOREIGN KEY (HomeroomTeacherId)   REFERENCES Teachers             (TeacherId);
ALTER TABLE ClassEnrollments         ADD CONSTRAINT FK_ClassEnrollments_Classes     FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE ClassEnrollments         ADD CONSTRAINT FK_ClassEnrollments_Students    FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE TeacherClassAssignments  ADD CONSTRAINT FK_TCA_Teachers                 FOREIGN KEY (TeacherId)           REFERENCES Teachers             (TeacherId);
ALTER TABLE TeacherClassAssignments  ADD CONSTRAINT FK_TCA_Classes                  FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE TeacherClassAssignments  ADD CONSTRAINT FK_TCA_Subjects                 FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE TeacherClassAssignments  ADD CONSTRAINT FK_TCA_SchoolYears              FOREIGN KEY (SchoolYearId)        REFERENCES SchoolYears          (SchoolYearId);
ALTER TABLE TimetableSlots           ADD CONSTRAINT FK_Timetable_Classes            FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE TimetableSlots           ADD CONSTRAINT FK_Timetable_Subjects           FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE TimetableSlots           ADD CONSTRAINT FK_Timetable_Teachers           FOREIGN KEY (TeacherId)           REFERENCES Teachers             (TeacherId);
ALTER TABLE TimetableSlots           ADD CONSTRAINT FK_Timetable_Semesters          FOREIGN KEY (SemesterId)          REFERENCES Semesters            (SemesterId);
ALTER TABLE LessonSessions           ADD CONSTRAINT FK_LessonSessions_Timetable     FOREIGN KEY (TimetableSlotId)     REFERENCES TimetableSlots       (TimetableSlotId);
ALTER TABLE LessonSessions           ADD CONSTRAINT FK_LessonSessions_Classes       FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE LessonSessions           ADD CONSTRAINT FK_LessonSessions_Subjects      FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE LessonSessions           ADD CONSTRAINT FK_LessonSessions_Teachers      FOREIGN KEY (TeacherId)           REFERENCES Teachers             (TeacherId);
ALTER TABLE AttendanceRecords        ADD CONSTRAINT FK_Attendance_Lessons           FOREIGN KEY (LessonSessionId)     REFERENCES LessonSessions       (LessonSessionId);
ALTER TABLE AttendanceRecords        ADD CONSTRAINT FK_Attendance_Students          FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE AttendanceRecords        ADD CONSTRAINT FK_Attendance_RecordedBy        FOREIGN KEY (RecordedBy)          REFERENCES Users                (UserId);
ALTER TABLE Assessments              ADD CONSTRAINT FK_Assessments_Classes          FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE Assessments              ADD CONSTRAINT FK_Assessments_Subjects         FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE Assessments              ADD CONSTRAINT FK_Assessments_Teachers         FOREIGN KEY (TeacherId)           REFERENCES Teachers             (TeacherId);
ALTER TABLE Assessments              ADD CONSTRAINT FK_Assessments_Semesters        FOREIGN KEY (SemesterId)          REFERENCES Semesters            (SemesterId);
ALTER TABLE Assessments              ADD CONSTRAINT FK_Assessments_Types            FOREIGN KEY (AssessmentTypeId)    REFERENCES AssessmentTypes      (AssessmentTypeId);
ALTER TABLE StudentMarks             ADD CONSTRAINT FK_StudentMarks_Assessments     FOREIGN KEY (AssessmentId)        REFERENCES Assessments          (AssessmentId);
ALTER TABLE StudentMarks             ADD CONSTRAINT FK_StudentMarks_Students        FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE StudentMarks             ADD CONSTRAINT FK_StudentMarks_Teachers        FOREIGN KEY (GradedBy)            REFERENCES Teachers             (TeacherId);
ALTER TABLE SkillAreas               ADD CONSTRAINT FK_SkillAreas_Subjects          FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE AssessmentSkillEvaluations ADD CONSTRAINT FK_Evaluations_Marks         FOREIGN KEY (StudentMarkId)       REFERENCES StudentMarks         (StudentMarkId);
ALTER TABLE AssessmentSkillEvaluations ADD CONSTRAINT FK_Evaluations_Skills        FOREIGN KEY (SkillAreaId)         REFERENCES SkillAreas           (SkillAreaId);
ALTER TABLE StudyResources           ADD CONSTRAINT FK_Resources_Subjects           FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE StudyResources           ADD CONSTRAINT FK_Resources_Classes            FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE StudyResources           ADD CONSTRAINT FK_Resources_UploadedBy         FOREIGN KEY (UploadedBy)          REFERENCES Users                (UserId);
ALTER TABLE AiKnowledgeChunks        ADD CONSTRAINT FK_AiChunks_Resources           FOREIGN KEY (ResourceId)          REFERENCES StudyResources       (ResourceId);
ALTER TABLE AiRecommendationRuns     ADD CONSTRAINT FK_AiRuns_Students              FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE AiRecommendationRuns     ADD CONSTRAINT FK_AiRuns_Subjects              FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE LearningPaths            ADD CONSTRAINT FK_LearningPaths_Students       FOREIGN KEY (StudentId)           REFERENCES Students             (StudentId);
ALTER TABLE LearningPaths            ADD CONSTRAINT FK_LearningPaths_Subjects       FOREIGN KEY (SubjectId)           REFERENCES Subjects             (SubjectId);
ALTER TABLE LearningPaths            ADD CONSTRAINT FK_LearningPaths_AiRuns         FOREIGN KEY (AiRunId)             REFERENCES AiRecommendationRuns (AiRunId);
ALTER TABLE LearningPathItems        ADD CONSTRAINT FK_LPI_Paths                    FOREIGN KEY (LearningPathId)      REFERENCES LearningPaths        (LearningPathId);
ALTER TABLE LearningPathItems        ADD CONSTRAINT FK_LPI_Skills                   FOREIGN KEY (SkillAreaId)         REFERENCES SkillAreas           (SkillAreaId);
ALTER TABLE LearningPathItems        ADD CONSTRAINT FK_LPI_Resources                FOREIGN KEY (ResourceId)          REFERENCES StudyResources       (ResourceId);
ALTER TABLE ChatGroups               ADD CONSTRAINT FK_ChatGroups_Classes            FOREIGN KEY (ClassId)             REFERENCES Classes              (ClassId);
ALTER TABLE ChatGroups               ADD CONSTRAINT FK_ChatGroups_SchoolYears        FOREIGN KEY (SchoolYearId)        REFERENCES SchoolYears          (SchoolYearId);
ALTER TABLE ChatGroupMembers         ADD CONSTRAINT FK_CGM_Groups                   FOREIGN KEY (ChatGroupId)         REFERENCES ChatGroups           (ChatGroupId);
ALTER TABLE ChatGroupMembers         ADD CONSTRAINT FK_CGM_Users                    FOREIGN KEY (UserId)              REFERENCES Users                (UserId);
ALTER TABLE ChatMessages             ADD CONSTRAINT FK_ChatMessages_Groups           FOREIGN KEY (ChatGroupId)         REFERENCES ChatGroups           (ChatGroupId);
ALTER TABLE ChatMessages             ADD CONSTRAINT FK_ChatMessages_Users            FOREIGN KEY (SenderUserId)        REFERENCES Users                (UserId);
ALTER TABLE Notifications            ADD CONSTRAINT FK_Notifications_Users           FOREIGN KEY (SenderUserId)        REFERENCES Users                (UserId);
ALTER TABLE NotificationRecipients   ADD CONSTRAINT FK_NR_Notifications             FOREIGN KEY (NotificationId)      REFERENCES Notifications        (NotificationId);
ALTER TABLE NotificationRecipients   ADD CONSTRAINT FK_NR_Users                     FOREIGN KEY (UserId)              REFERENCES Users                (UserId);
ALTER TABLE FeedbackTickets          ADD CONSTRAINT FK_Feedback_Sender              FOREIGN KEY (SenderUserId)        REFERENCES Users                (UserId);
ALTER TABLE FeedbackTickets          ADD CONSTRAINT FK_Feedback_Students            FOREIGN KEY (RelatedStudentId)    REFERENCES Students             (StudentId);
ALTER TABLE FeedbackTickets          ADD CONSTRAINT FK_Feedback_Handler             FOREIGN KEY (HandledBy)           REFERENCES Users                (UserId);
ALTER TABLE NewsPosts                ADD CONSTRAINT FK_News_Users                   FOREIGN KEY (AuthorUserId)        REFERENCES Users                (UserId);
ALTER TABLE RegistrationRequests     ADD CONSTRAINT FK_RegReq_ReviewedBy            FOREIGN KEY (ReviewedBy)          REFERENCES Users                (UserId);
GO

-- ══════════════════════════════════════════════════════════════
--  SECTION 3 — SEED DATA
-- ══════════════════════════════════════════════════════════════
USE eStudentDB;
GO
SET NOCOUNT ON;

-- BCrypt hashes (cost=10, generated by bcrypt npm package)
DECLARE @HASH_ADMIN   NVARCHAR(255) = N'$2b$10$lqcI1stJUbJv/NCFLe8Lf.07rJA91bp9KNy/zEgSWXZHMoA5k7inO'; -- Admin@123
DECLARE @HASH_TEACHER NVARCHAR(255) = N'$2b$10$og80RtX2vDQrc/.hh7p16OuAK2V9K9OX1.QfZimiPforM.8uL7KVS'; -- Teacher@123
DECLARE @HASH_STUDENT NVARCHAR(255) = N'$2b$10$vac65OsMh8nWqPJNA..dq.bT91e7FyCCil3AbS22694qSbE32TAUW'; -- Student@123
DECLARE @HASH_PARENT  NVARCHAR(255) = N'$2b$10$8Rr5QEk2f2uewpCgjr6.Q.WtzMc5wqs60mDk6iVH/JyDmWdfIYlLG'; -- Parent@123

-- ── 1. ROLES ──────────────────────────────────────────────────
INSERT INTO Roles (Code, Name) VALUES
    (N'ADMIN',   N'Administrator'),
    (N'TEACHER', N'Teacher'),
    (N'STUDENT', N'Student'),
    (N'PARENT',  N'Parent');
DECLARE @rAdmin   INT = (SELECT RoleId FROM Roles WHERE Code = N'ADMIN');
DECLARE @rTeacher INT = (SELECT RoleId FROM Roles WHERE Code = N'TEACHER');
DECLARE @rStudent INT = (SELECT RoleId FROM Roles WHERE Code = N'STUDENT');
DECLARE @rParent  INT = (SELECT RoleId FROM Roles WHERE Code = N'PARENT');

-- ── 2. SUBJECTS (10) ──────────────────────────────────────────
INSERT INTO Subjects (Code, Name, Description, IsActive) VALUES
    (N'MATH', N'Mathematics',        N'Algebra, Geometry, Calculus',              1),
    (N'LIT',  N'Literature',         N'Vietnamese and world literature',          1),
    (N'ENG',  N'English',            N'English language and communication',       1),
    (N'PHY',  N'Physics',            N'Mechanics, Electricity, Optics',           1),
    (N'CHEM', N'Chemistry',          N'Organic and inorganic chemistry',          1),
    (N'BIO',  N'Biology',            N'Cell biology, Ecology, Genetics',          1),
    (N'HIS',  N'History',            N'Vietnamese and world history',             1),
    (N'GEO',  N'Geography',          N'Physical and human geography',             1),
    (N'CS',   N'Computer Science',   N'Programming, Algorithms, IT foundations', 1),
    (N'PE',   N'Physical Education', N'Sports, Health, Fitness',                 1);
DECLARE @subMath INT = (SELECT SubjectId FROM Subjects WHERE Code = N'MATH');
DECLARE @subLit  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'LIT');
DECLARE @subEng  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'ENG');
DECLARE @subPhy  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'PHY');
DECLARE @subChem INT = (SELECT SubjectId FROM Subjects WHERE Code = N'CHEM');
DECLARE @subBio  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'BIO');
DECLARE @subHis  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'HIS');
DECLARE @subGeo  INT = (SELECT SubjectId FROM Subjects WHERE Code = N'GEO');
DECLARE @subCs   INT = (SELECT SubjectId FROM Subjects WHERE Code = N'CS');
DECLARE @subPe   INT = (SELECT SubjectId FROM Subjects WHERE Code = N'PE');

-- ── 3. GRADES ─────────────────────────────────────────────────
INSERT INTO Grades (Code, Name) VALUES
    (N'G10', N'Grade 10'), (N'G11', N'Grade 11'), (N'G12', N'Grade 12');
DECLARE @g10 INT = (SELECT GradeId FROM Grades WHERE Code = N'G10');
DECLARE @g11 INT = (SELECT GradeId FROM Grades WHERE Code = N'G11');

-- ── 4. ASSESSMENT TYPES ───────────────────────────────────────
INSERT INTO AssessmentTypes (Code, Name, DefaultWeight) VALUES
    (N'QUIZ',    N'Quiz',        0.10),
    (N'MIDTERM', N'Midterm Exam', 0.30),
    (N'FINAL',   N'Final Exam',  0.60);
DECLARE @atQuiz  INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'QUIZ');
DECLARE @atMid   INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'MIDTERM');
DECLARE @atFinal INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'FINAL');

-- ── 5. SCHOOL CONTACTS ────────────────────────────────────────
INSERT INTO SchoolContacts (Name, Email, Phone, Address, WorkingHours, IsActive) VALUES
    (N'School Office',    N'office@estudiez.edu.vn',   N'(028) 3800-0001', N'1 Nguyen Trai, District 1, HCMC', N'Mon-Fri 07:00-17:00', 1),
    (N'Academic Affairs', N'academic@estudiez.edu.vn', N'(028) 3800-0002', N'1 Nguyen Trai, District 1, HCMC', N'Mon-Fri 07:30-16:30', 1),
    (N'Student Support',  N'support@estudiez.edu.vn',  N'(028) 3800-0003', N'1 Nguyen Trai, District 1, HCMC', N'Mon-Fri 08:00-16:00', 1),
    (N'Parent Liaison',   N'parents@estudiez.edu.vn',  N'(028) 3800-0004', N'1 Nguyen Trai, District 1, HCMC', N'Mon-Fri 08:00-15:00', 1),
    (N'IT Help Desk',     N'it@estudiez.edu.vn',       N'(028) 3800-0099', N'1 Nguyen Trai, District 1, HCMC', N'Mon-Fri 08:00-17:00', 1);

-- ── 6. USERS (43 total) ───────────────────────────────────────
--  1 admin | 10 teachers | 16 students (10A1/10A2/11A1/11A2) | 16 parents
DECLARE @uAdmin UNIQUEIDENTIFIER = NEWID();
DECLARE @uT01 UNIQUEIDENTIFIER = NEWID(); DECLARE @uT02 UNIQUEIDENTIFIER = NEWID();
DECLARE @uT03 UNIQUEIDENTIFIER = NEWID(); DECLARE @uT04 UNIQUEIDENTIFIER = NEWID();
DECLARE @uT05 UNIQUEIDENTIFIER = NEWID(); DECLARE @uT06 UNIQUEIDENTIFIER = NEWID();
DECLARE @uT07 UNIQUEIDENTIFIER = NEWID(); DECLARE @uT08 UNIQUEIDENTIFIER = NEWID();
DECLARE @uT09 UNIQUEIDENTIFIER = NEWID(); DECLARE @uT10 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS01 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS02 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS03 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS04 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS05 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS06 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS07 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS08 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS09 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS10 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS11 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS12 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS13 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS14 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS15 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS16 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP01 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP02 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP03 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP04 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP05 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP06 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP07 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP08 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP09 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP10 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP11 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP12 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP13 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP14 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP15 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP16 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Users (UserId, RoleId, Username, PasswordHash, FullName, Email, Phone, IsActive) VALUES
(@uAdmin,@rAdmin,  N'admin',        @HASH_ADMIN,  N'System Administrator', N'admin@estudiez.edu.vn',     N'0901000000',1),
(@uT01,  @rTeacher,N'teacher.math', @HASH_TEACHER,N'Nguyen Van Minh',       N'minh.nv@estudiez.edu.vn',  N'0901000001',1),
(@uT02,  @rTeacher,N'teacher.lit',  @HASH_TEACHER,N'Tran Thi Lan',          N'lan.tt@estudiez.edu.vn',   N'0901000002',1),
(@uT03,  @rTeacher,N'teacher.eng',  @HASH_TEACHER,N'Le Hoang Nam',          N'nam.lh@estudiez.edu.vn',   N'0901000003',1),
(@uT04,  @rTeacher,N'teacher.phy',  @HASH_TEACHER,N'Pham Duc Khanh',        N'khanh.pd@estudiez.edu.vn', N'0901000004',1),
(@uT05,  @rTeacher,N'teacher.chem', @HASH_TEACHER,N'Nguyen Thi Thu',        N'thu.nt@estudiez.edu.vn',   N'0901000005',1),
(@uT06,  @rTeacher,N'teacher.bio',  @HASH_TEACHER,N'Bui Van Tung',          N'tung.bv@estudiez.edu.vn',  N'0901000006',1),
(@uT07,  @rTeacher,N'teacher.his',  @HASH_TEACHER,N'Vo Thi Huong',          N'huong.vt@estudiez.edu.vn', N'0901000007',1),
(@uT08,  @rTeacher,N'teacher.geo',  @HASH_TEACHER,N'Dang Quoc Bao',         N'bao.dq@estudiez.edu.vn',   N'0901000008',1),
(@uT09,  @rTeacher,N'teacher.cs',   @HASH_TEACHER,N'Le Thi Phuong',         N'phuong.lt@estudiez.edu.vn',N'0901000009',1),
(@uT10,  @rTeacher,N'teacher.pe',   @HASH_TEACHER,N'Nguyen Van Thanh',      N'thanh.nv2@estudiez.edu.vn',N'0901000010',1),
-- Students: 10A1
(@uS01,  @rStudent,N'bao.pq',   @HASH_STUDENT,N'Pham Quoc Bao',    NULL,N'0912001001',1),
(@uS02,  @rStudent,N'mai.nt',   @HASH_STUDENT,N'Nguyen Thi Mai',   NULL,N'0912001002',1),
(@uS03,  @rStudent,N'duc.tv',   @HASH_STUDENT,N'Tran Van Duc',     NULL,N'0912001003',1),
(@uS04,  @rStudent,N'linh.pn',  @HASH_STUDENT,N'Phan Ngoc Linh',   NULL,N'0912001004',1),
-- Students: 10A2
(@uS05,  @rStudent,N'hung.lt',  @HASH_STUDENT,N'Le Thanh Hung',    NULL,N'0912001005',1),
(@uS06,  @rStudent,N'thuy.ht',  @HASH_STUDENT,N'Ho Thi Thuy',      NULL,N'0912001006',1),
(@uS07,  @rStudent,N'an.tq',    @HASH_STUDENT,N'Tran Quoc An',     NULL,N'0912001007',1),
(@uS08,  @rStudent,N'vy.nd',    @HASH_STUDENT,N'Nguyen Dieu Vy',   NULL,N'0912001008',1),
-- Students: 11A1
(@uS09,  @rStudent,N'hoa.lt',   @HASH_STUDENT,N'Le Thi Hoa',       NULL,N'0912001009',1),
(@uS10,  @rStudent,N'khoa.vm',  @HASH_STUDENT,N'Vo Minh Khoa',     NULL,N'0912001010',1),
(@uS11,  @rStudent,N'lan.nq',   @HASH_STUDENT,N'Nguyen Quoc Lan',  NULL,N'0912001011',1),
(@uS12,  @rStudent,N'minh.bd',  @HASH_STUDENT,N'Bui Duc Minh',     NULL,N'0912001012',1),
-- Students: 11A2
(@uS13,  @rStudent,N'thu.ph',   @HASH_STUDENT,N'Pham Hong Thu',    NULL,N'0912001013',1),
(@uS14,  @rStudent,N'long.dt',  @HASH_STUDENT,N'Dang Thanh Long',  NULL,N'0912001014',1),
(@uS15,  @rStudent,N'nam.bv',   @HASH_STUDENT,N'Bui Van Nam',      NULL,N'0912001015',1),
(@uS16,  @rStudent,N'huong.lm', @HASH_STUDENT,N'Le Thi Huong',     NULL,N'0912001016',1),
-- Parents
(@uP01,@rParent,N'parent.bao',  @HASH_PARENT,N'Pham Van Long',    N'long.pv@gmail.com',   N'0903001001',1),
(@uP02,@rParent,N'parent.mai',  @HASH_PARENT,N'Nguyen Thi Nga',   N'nga.nt@gmail.com',    N'0903001002',1),
(@uP03,@rParent,N'parent.duc',  @HASH_PARENT,N'Tran Van Hai',     N'hai.tv@gmail.com',    N'0903001003',1),
(@uP04,@rParent,N'parent.linh', @HASH_PARENT,N'Phan Thi Mai',     N'mai.pt@gmail.com',    N'0903001004',1),
(@uP05,@rParent,N'parent.hung', @HASH_PARENT,N'Le Van Phuong',    N'phuong.lv@gmail.com', N'0903001005',1),
(@uP06,@rParent,N'parent.thuy', @HASH_PARENT,N'Ho Van Binh',      N'binh.hv@gmail.com',   N'0903001006',1),
(@uP07,@rParent,N'parent.an',   @HASH_PARENT,N'Tran Thi Hoa',     N'hoa.tt@gmail.com',    N'0903001007',1),
(@uP08,@rParent,N'parent.vy',   @HASH_PARENT,N'Nguyen Van Hieu',  N'hieu.nv@gmail.com',   N'0903001008',1),
(@uP09,@rParent,N'parent.hoa',  @HASH_PARENT,N'Le Van Thanh',     N'thanh.lv@gmail.com',  N'0903001009',1),
(@uP10,@rParent,N'parent.khoa', @HASH_PARENT,N'Vo Thi Kim',       N'kim.vt@gmail.com',    N'0903001010',1),
(@uP11,@rParent,N'parent.lan',  @HASH_PARENT,N'Nguyen Van Cuong', N'cuong.nv@gmail.com',  N'0903001011',1),
(@uP12,@rParent,N'parent.minh', @HASH_PARENT,N'Bui Thi Lan',      N'lan.bt@gmail.com',    N'0903001012',1),
(@uP13,@rParent,N'parent.thu',  @HASH_PARENT,N'Pham Van Duc',     N'duc.pv@gmail.com',    N'0903001013',1),
(@uP14,@rParent,N'parent.long', @HASH_PARENT,N'Dang Thi Linh',    N'linh.dt@gmail.com',   N'0903001014',1),
(@uP15,@rParent,N'parent.nam',  @HASH_PARENT,N'Bui Van Son',      N'son.bv@gmail.com',    N'0903001015',1),
(@uP16,@rParent,N'parent.huong',@HASH_PARENT,N'Le Van Minh',      N'minh.lv2@gmail.com',  N'0903001016',1);

-- ── 7. TEACHERS (10 — one per subject) ────────────────────────
DECLARE @tId01 UNIQUEIDENTIFIER = NEWID(); DECLARE @tId02 UNIQUEIDENTIFIER = NEWID();
DECLARE @tId03 UNIQUEIDENTIFIER = NEWID(); DECLARE @tId04 UNIQUEIDENTIFIER = NEWID();
DECLARE @tId05 UNIQUEIDENTIFIER = NEWID(); DECLARE @tId06 UNIQUEIDENTIFIER = NEWID();
DECLARE @tId07 UNIQUEIDENTIFIER = NEWID(); DECLARE @tId08 UNIQUEIDENTIFIER = NEWID();
DECLARE @tId09 UNIQUEIDENTIFIER = NEWID(); DECLARE @tId10 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Teachers (TeacherId, UserId, EmployeeCode, SubjectId, Qualification) VALUES
(@tId01,@uT01,N'TCH001',@subMath,N'MSc Mathematics'),
(@tId02,@uT02,N'TCH002',@subLit, N'BA Literature'),
(@tId03,@uT03,N'TCH003',@subEng, N'MA TESOL'),
(@tId04,@uT04,N'TCH004',@subPhy, N'BSc Physics'),
(@tId05,@uT05,N'TCH005',@subChem,N'BSc Chemistry'),
(@tId06,@uT06,N'TCH006',@subBio, N'BSc Biology'),
(@tId07,@uT07,N'TCH007',@subHis, N'BA History'),
(@tId08,@uT08,N'TCH008',@subGeo, N'BSc Geography'),
(@tId09,@uT09,N'TCH009',@subCs,  N'BSc Computer Science'),
(@tId10,@uT10,N'TCH010',@subPe,  N'BSc Sports Science');

-- ── 8. STUDENTS (16) ──────────────────────────────────────────
DECLARE @sId01 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId02 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId03 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId04 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId05 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId06 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId07 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId08 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId09 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId10 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId11 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId12 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId13 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId14 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId15 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId16 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Students (StudentId,UserId,StudentCode,DateOfBirth,Gender,Address,AdmissionDate,Status) VALUES
(@sId01,@uS01,N'STU001','2008-01-10',N'Male',  N'12 Le Loi, District 1, HCMC',           '2022-09-01',N'ACTIVE'),
(@sId02,@uS02,N'STU002','2008-03-15',N'Female',N'34 Hai Ba Trung, District 3, HCMC',     '2022-09-01',N'ACTIVE'),
(@sId03,@uS03,N'STU003','2008-05-20',N'Male',  N'56 Nguyen Hue, District 1, HCMC',       '2022-09-01',N'ACTIVE'),
(@sId04,@uS04,N'STU004','2008-07-25',N'Female',N'78 Tran Hung Dao, District 5, HCMC',    '2022-09-01',N'ACTIVE'),
(@sId05,@uS05,N'STU005','2008-09-12',N'Male',  N'90 Vo Thi Sau, District 3, HCMC',       '2022-09-01',N'ACTIVE'),
(@sId06,@uS06,N'STU006','2008-11-08',N'Female',N'15 Dien Bien Phu, Binh Thanh, HCMC',   '2022-09-01',N'ACTIVE'),
(@sId07,@uS07,N'STU007','2008-02-18',N'Male',  N'23 Cach Mang Thang 8, District 10',     '2022-09-01',N'ACTIVE'),
(@sId08,@uS08,N'STU008','2008-06-22',N'Female',N'45 Nguyen Trai, District 5, HCMC',      '2022-09-01',N'ACTIVE'),
(@sId09,@uS09,N'STU009','2007-01-05',N'Female',N'67 Ly Thuong Kiet, District 10, HCMC',  '2021-09-01',N'ACTIVE'),
(@sId10,@uS10,N'STU010','2007-04-19',N'Male',  N'89 Nguyen Dinh Chieu, District 3',      '2021-09-01',N'ACTIVE'),
(@sId11,@uS11,N'STU011','2007-07-23',N'Female',N'11 Ba Thang Hai, District 10, HCMC',    '2021-09-01',N'ACTIVE'),
(@sId12,@uS12,N'STU012','2007-11-17',N'Male',  N'33 Nguyen Van Cu, District 5, HCMC',    '2021-09-01',N'ACTIVE'),
(@sId13,@uS13,N'STU013','2007-03-08',N'Female',N'55 Le Van Sy, District 3, HCMC',        '2021-09-01',N'ACTIVE'),
(@sId14,@uS14,N'STU014','2007-06-14',N'Male',  N'77 Nguyen Gia Thieu, District 3',       '2021-09-01',N'ACTIVE'),
(@sId15,@uS15,N'STU015','2007-08-30',N'Male',  N'99 Nam Ky Khoi Nghia, District 3',      '2021-09-01',N'ACTIVE'),
(@sId16,@uS16,N'STU016','2007-10-14',N'Female',N'21 Phan Xich Long, Phu Nhuan, HCMC',    '2021-09-01',N'ACTIVE');

-- ── 9. PARENTS (16) ───────────────────────────────────────────
DECLARE @pId01 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId02 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId03 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId04 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId05 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId06 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId07 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId08 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId09 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId10 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId11 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId12 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId13 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId14 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId15 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId16 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Parents (ParentId,UserId,Occupation,Address) VALUES
(@pId01,@uP01,N'Engineer',      N'12 Le Loi, District 1, HCMC'),
(@pId02,@uP02,N'Teacher',       N'34 Hai Ba Trung, District 3, HCMC'),
(@pId03,@uP03,N'Accountant',    N'56 Nguyen Hue, District 1, HCMC'),
(@pId04,@uP04,N'Nurse',         N'78 Tran Hung Dao, District 5, HCMC'),
(@pId05,@uP05,N'Businessman',   N'90 Vo Thi Sau, District 3, HCMC'),
(@pId06,@uP06,N'Doctor',        N'15 Dien Bien Phu, Binh Thanh, HCMC'),
(@pId07,@uP07,N'Civil Servant', N'23 Cach Mang Thang 8, District 10'),
(@pId08,@uP08,N'IT Specialist', N'45 Nguyen Trai, District 5, HCMC'),
(@pId09,@uP09,N'Lawyer',        N'67 Ly Thuong Kiet, District 10, HCMC'),
(@pId10,@uP10,N'Chef',          N'89 Nguyen Dinh Chieu, District 3'),
(@pId11,@uP11,N'Pharmacist',    N'11 Ba Thang Hai, District 10, HCMC'),
(@pId12,@uP12,N'Architect',     N'33 Nguyen Van Cu, District 5, HCMC'),
(@pId13,@uP13,N'Police Officer',N'55 Le Van Sy, District 3, HCMC'),
(@pId14,@uP14,N'Journalist',    N'77 Nguyen Gia Thieu, District 3'),
(@pId15,@uP15,N'Mechanic',      N'99 Nam Ky Khoi Nghia, District 3'),
(@pId16,@uP16,N'Electrician',   N'21 Phan Xich Long, Phu Nhuan, HCMC');

-- ── 10. STUDENT-PARENT LINKS ──────────────────────────────────
INSERT INTO StudentParentLinks (StudentId,ParentId,Relationship,IsPrimaryContact) VALUES
(@sId01,@pId01,N'Father',1),(@sId02,@pId02,N'Mother',1),
(@sId03,@pId03,N'Father',1),(@sId04,@pId04,N'Mother',1),
(@sId05,@pId05,N'Father',1),(@sId06,@pId06,N'Father',1),
(@sId07,@pId07,N'Mother',1),(@sId08,@pId08,N'Father',1),
(@sId09,@pId09,N'Father',1),(@sId10,@pId10,N'Mother',1),
(@sId11,@pId11,N'Father',1),(@sId12,@pId12,N'Mother',1),
(@sId13,@pId13,N'Father',1),(@sId14,@pId14,N'Mother',1),
(@sId15,@pId15,N'Father',1),(@sId16,@pId16,N'Father',1);

-- ── 11. SCHOOL STRUCTURE ──────────────────────────────────────
INSERT INTO SchoolYears (Name,StartDate,EndDate,IsCurrent)
    VALUES (N'2025-2026','2025-09-01','2026-06-30',1);
DECLARE @syId INT = SCOPE_IDENTITY();

INSERT INTO Semesters (SchoolYearId,Name,StartDate,EndDate)
    VALUES (@syId,N'Semester 1','2025-09-01','2026-01-15');
DECLARE @sem1 INT = SCOPE_IDENTITY();

INSERT INTO Semesters (SchoolYearId,Name,StartDate,EndDate)
    VALUES (@syId,N'Semester 2','2026-01-20','2026-06-30');
DECLARE @sem2 INT = SCOPE_IDENTITY();

-- Classes
INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g10,N'10A1',@tId01,N'REGULAR',N'101',1);
DECLARE @c10A1 INT = SCOPE_IDENTITY();

INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g10,N'10A2',@tId04,N'REGULAR',N'102',1);
DECLARE @c10A2 INT = SCOPE_IDENTITY();

INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g11,N'11A1',@tId02,N'REGULAR',N'201',1);
DECLARE @c11A1 INT = SCOPE_IDENTITY();

INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g11,N'11A2',@tId03,N'REGULAR',N'202',1);
DECLARE @c11A2 INT = SCOPE_IDENTITY();

-- Enrollments (4 per class)
INSERT INTO ClassEnrollments (ClassId,StudentId,EnrolledAt,Status) VALUES
(@c10A1,@sId01,'2025-09-01',N'ACTIVE'),(@c10A1,@sId02,'2025-09-01',N'ACTIVE'),
(@c10A1,@sId03,'2025-09-01',N'ACTIVE'),(@c10A1,@sId04,'2025-09-01',N'ACTIVE'),
(@c10A2,@sId05,'2025-09-01',N'ACTIVE'),(@c10A2,@sId06,'2025-09-01',N'ACTIVE'),
(@c10A2,@sId07,'2025-09-01',N'ACTIVE'),(@c10A2,@sId08,'2025-09-01',N'ACTIVE'),
(@c11A1,@sId09,'2025-09-01',N'ACTIVE'),(@c11A1,@sId10,'2025-09-01',N'ACTIVE'),
(@c11A1,@sId11,'2025-09-01',N'ACTIVE'),(@c11A1,@sId12,'2025-09-01',N'ACTIVE'),
(@c11A2,@sId13,'2025-09-01',N'ACTIVE'),(@c11A2,@sId14,'2025-09-01',N'ACTIVE'),
(@c11A2,@sId15,'2025-09-01',N'ACTIVE'),(@c11A2,@sId16,'2025-09-01',N'ACTIVE');

-- Teacher-class assignments (10 teachers x 4 classes = 40)
INSERT INTO TeacherClassAssignments (TeacherId,ClassId,SubjectId,SchoolYearId) VALUES
(@tId01,@c10A1,@subMath,@syId),(@tId02,@c10A1,@subLit, @syId),(@tId03,@c10A1,@subEng, @syId),
(@tId04,@c10A1,@subPhy, @syId),(@tId05,@c10A1,@subChem,@syId),(@tId06,@c10A1,@subBio, @syId),
(@tId07,@c10A1,@subHis, @syId),(@tId08,@c10A1,@subGeo, @syId),(@tId09,@c10A1,@subCs,  @syId),(@tId10,@c10A1,@subPe,@syId),
(@tId01,@c10A2,@subMath,@syId),(@tId02,@c10A2,@subLit, @syId),(@tId03,@c10A2,@subEng, @syId),
(@tId04,@c10A2,@subPhy, @syId),(@tId05,@c10A2,@subChem,@syId),(@tId06,@c10A2,@subBio, @syId),
(@tId07,@c10A2,@subHis, @syId),(@tId08,@c10A2,@subGeo, @syId),(@tId09,@c10A2,@subCs,  @syId),(@tId10,@c10A2,@subPe,@syId),
(@tId01,@c11A1,@subMath,@syId),(@tId02,@c11A1,@subLit, @syId),(@tId03,@c11A1,@subEng, @syId),
(@tId04,@c11A1,@subPhy, @syId),(@tId05,@c11A1,@subChem,@syId),(@tId06,@c11A1,@subBio, @syId),
(@tId07,@c11A1,@subHis, @syId),(@tId08,@c11A1,@subGeo, @syId),(@tId09,@c11A1,@subCs,  @syId),(@tId10,@c11A1,@subPe,@syId),
(@tId01,@c11A2,@subMath,@syId),(@tId02,@c11A2,@subLit, @syId),(@tId03,@c11A2,@subEng, @syId),
(@tId04,@c11A2,@subPhy, @syId),(@tId05,@c11A2,@subChem,@syId),(@tId06,@c11A2,@subBio, @syId),
(@tId07,@c11A2,@subHis, @syId),(@tId08,@c11A2,@subGeo, @syId),(@tId09,@c11A2,@subCs,  @syId),(@tId10,@c11A2,@subPe,@syId);

-- ── 12. TIMETABLE (Mon-Fri x 5 periods x 4 classes = 100 slots) ──
-- DayOfWeek: 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri
-- Periods:   P1=07:30-08:15  P2=08:25-09:10  P3=09:20-10:05  P4=10:15-11:00  P5=11:10-11:55
-- 10A1: Mon/Wed/Fri: MATH LIT ENG PHY CHEM   |  Tue/Thu: BIO HIS GEO CS PE
-- 10A2: Mon/Wed/Fri: PHY MATH LIT ENG CS      |  Tue/Thu: CHEM BIO HIS GEO PE
-- 11A1: Mon/Wed/Fri: LIT MATH ENG PHY CS      |  Tue/Thu: CHEM BIO HIS GEO PE
-- 11A2: Mon/Wed/Fri: ENG LIT MATH PHY BIO     |  Tue/Thu: CHEM HIS GEO CS PE
DECLARE @eff DATE = '2025-09-05';
INSERT INTO TimetableSlots (ClassId,SubjectId,TeacherId,SemesterId,DayOfWeek,PeriodNo,StartTime,EndTime,Room,EffectiveFrom) VALUES
-- 10A1 Mon
(@c10A1,@subMath,@tId01,@sem1,1,1,'07:30','08:15',N'101',@eff),(@c10A1,@subLit, @tId02,@sem1,1,2,'08:25','09:10',N'101',@eff),
(@c10A1,@subEng, @tId03,@sem1,1,3,'09:20','10:05',N'101',@eff),(@c10A1,@subPhy, @tId04,@sem1,1,4,'10:15','11:00',N'101',@eff),
(@c10A1,@subChem,@tId05,@sem1,1,5,'11:10','11:55',N'101',@eff),
-- 10A1 Tue
(@c10A1,@subBio, @tId06,@sem1,2,1,'07:30','08:15',N'101',@eff),(@c10A1,@subHis, @tId07,@sem1,2,2,'08:25','09:10',N'101',@eff),
(@c10A1,@subGeo, @tId08,@sem1,2,3,'09:20','10:05',N'101',@eff),(@c10A1,@subCs,  @tId09,@sem1,2,4,'10:15','11:00',N'101',@eff),
(@c10A1,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'101',@eff),
-- 10A1 Wed
(@c10A1,@subMath,@tId01,@sem1,3,1,'07:30','08:15',N'101',@eff),(@c10A1,@subLit, @tId02,@sem1,3,2,'08:25','09:10',N'101',@eff),
(@c10A1,@subEng, @tId03,@sem1,3,3,'09:20','10:05',N'101',@eff),(@c10A1,@subPhy, @tId04,@sem1,3,4,'10:15','11:00',N'101',@eff),
(@c10A1,@subChem,@tId05,@sem1,3,5,'11:10','11:55',N'101',@eff),
-- 10A1 Thu
(@c10A1,@subBio, @tId06,@sem1,4,1,'07:30','08:15',N'101',@eff),(@c10A1,@subHis, @tId07,@sem1,4,2,'08:25','09:10',N'101',@eff),
(@c10A1,@subGeo, @tId08,@sem1,4,3,'09:20','10:05',N'101',@eff),(@c10A1,@subCs,  @tId09,@sem1,4,4,'10:15','11:00',N'101',@eff),
(@c10A1,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'101',@eff),
-- 10A1 Fri
(@c10A1,@subMath,@tId01,@sem1,5,1,'07:30','08:15',N'101',@eff),(@c10A1,@subLit, @tId02,@sem1,5,2,'08:25','09:10',N'101',@eff),
(@c10A1,@subEng, @tId03,@sem1,5,3,'09:20','10:05',N'101',@eff),(@c10A1,@subPhy, @tId04,@sem1,5,4,'10:15','11:00',N'101',@eff),
(@c10A1,@subChem,@tId05,@sem1,5,5,'11:10','11:55',N'101',@eff),
-- 10A2 Mon
(@c10A2,@subPhy, @tId04,@sem1,1,1,'07:30','08:15',N'102',@eff),(@c10A2,@subMath,@tId01,@sem1,1,2,'08:25','09:10',N'102',@eff),
(@c10A2,@subLit, @tId02,@sem1,1,3,'09:20','10:05',N'102',@eff),(@c10A2,@subEng, @tId03,@sem1,1,4,'10:15','11:00',N'102',@eff),
(@c10A2,@subCs,  @tId09,@sem1,1,5,'11:10','11:55',N'102',@eff),
-- 10A2 Tue
(@c10A2,@subChem,@tId05,@sem1,2,1,'07:30','08:15',N'102',@eff),(@c10A2,@subBio, @tId06,@sem1,2,2,'08:25','09:10',N'102',@eff),
(@c10A2,@subHis, @tId07,@sem1,2,3,'09:20','10:05',N'102',@eff),(@c10A2,@subGeo, @tId08,@sem1,2,4,'10:15','11:00',N'102',@eff),
(@c10A2,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'102',@eff),
-- 10A2 Wed
(@c10A2,@subPhy, @tId04,@sem1,3,1,'07:30','08:15',N'102',@eff),(@c10A2,@subMath,@tId01,@sem1,3,2,'08:25','09:10',N'102',@eff),
(@c10A2,@subLit, @tId02,@sem1,3,3,'09:20','10:05',N'102',@eff),(@c10A2,@subEng, @tId03,@sem1,3,4,'10:15','11:00',N'102',@eff),
(@c10A2,@subCs,  @tId09,@sem1,3,5,'11:10','11:55',N'102',@eff),
-- 10A2 Thu
(@c10A2,@subChem,@tId05,@sem1,4,1,'07:30','08:15',N'102',@eff),(@c10A2,@subBio, @tId06,@sem1,4,2,'08:25','09:10',N'102',@eff),
(@c10A2,@subHis, @tId07,@sem1,4,3,'09:20','10:05',N'102',@eff),(@c10A2,@subGeo, @tId08,@sem1,4,4,'10:15','11:00',N'102',@eff),
(@c10A2,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'102',@eff),
-- 10A2 Fri
(@c10A2,@subPhy, @tId04,@sem1,5,1,'07:30','08:15',N'102',@eff),(@c10A2,@subMath,@tId01,@sem1,5,2,'08:25','09:10',N'102',@eff),
(@c10A2,@subLit, @tId02,@sem1,5,3,'09:20','10:05',N'102',@eff),(@c10A2,@subEng, @tId03,@sem1,5,4,'10:15','11:00',N'102',@eff),
(@c10A2,@subCs,  @tId09,@sem1,5,5,'11:10','11:55',N'102',@eff),
-- 11A1 Mon
(@c11A1,@subLit, @tId02,@sem1,1,1,'07:30','08:15',N'201',@eff),(@c11A1,@subMath,@tId01,@sem1,1,2,'08:25','09:10',N'201',@eff),
(@c11A1,@subEng, @tId03,@sem1,1,3,'09:20','10:05',N'201',@eff),(@c11A1,@subPhy, @tId04,@sem1,1,4,'10:15','11:00',N'201',@eff),
(@c11A1,@subCs,  @tId09,@sem1,1,5,'11:10','11:55',N'201',@eff),
-- 11A1 Tue
(@c11A1,@subChem,@tId05,@sem1,2,1,'07:30','08:15',N'201',@eff),(@c11A1,@subBio, @tId06,@sem1,2,2,'08:25','09:10',N'201',@eff),
(@c11A1,@subHis, @tId07,@sem1,2,3,'09:20','10:05',N'201',@eff),(@c11A1,@subGeo, @tId08,@sem1,2,4,'10:15','11:00',N'201',@eff),
(@c11A1,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'201',@eff),
-- 11A1 Wed
(@c11A1,@subLit, @tId02,@sem1,3,1,'07:30','08:15',N'201',@eff),(@c11A1,@subMath,@tId01,@sem1,3,2,'08:25','09:10',N'201',@eff),
(@c11A1,@subEng, @tId03,@sem1,3,3,'09:20','10:05',N'201',@eff),(@c11A1,@subPhy, @tId04,@sem1,3,4,'10:15','11:00',N'201',@eff),
(@c11A1,@subCs,  @tId09,@sem1,3,5,'11:10','11:55',N'201',@eff),
-- 11A1 Thu
(@c11A1,@subChem,@tId05,@sem1,4,1,'07:30','08:15',N'201',@eff),(@c11A1,@subBio, @tId06,@sem1,4,2,'08:25','09:10',N'201',@eff),
(@c11A1,@subHis, @tId07,@sem1,4,3,'09:20','10:05',N'201',@eff),(@c11A1,@subGeo, @tId08,@sem1,4,4,'10:15','11:00',N'201',@eff),
(@c11A1,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'201',@eff),
-- 11A1 Fri
(@c11A1,@subLit, @tId02,@sem1,5,1,'07:30','08:15',N'201',@eff),(@c11A1,@subMath,@tId01,@sem1,5,2,'08:25','09:10',N'201',@eff),
(@c11A1,@subEng, @tId03,@sem1,5,3,'09:20','10:05',N'201',@eff),(@c11A1,@subPhy, @tId04,@sem1,5,4,'10:15','11:00',N'201',@eff),
(@c11A1,@subCs,  @tId09,@sem1,5,5,'11:10','11:55',N'201',@eff),
-- 11A2 Mon
(@c11A2,@subEng, @tId03,@sem1,1,1,'07:30','08:15',N'202',@eff),(@c11A2,@subLit, @tId02,@sem1,1,2,'08:25','09:10',N'202',@eff),
(@c11A2,@subMath,@tId01,@sem1,1,3,'09:20','10:05',N'202',@eff),(@c11A2,@subPhy, @tId04,@sem1,1,4,'10:15','11:00',N'202',@eff),
(@c11A2,@subBio, @tId06,@sem1,1,5,'11:10','11:55',N'202',@eff),
-- 11A2 Tue
(@c11A2,@subChem,@tId05,@sem1,2,1,'07:30','08:15',N'202',@eff),(@c11A2,@subHis, @tId07,@sem1,2,2,'08:25','09:10',N'202',@eff),
(@c11A2,@subGeo, @tId08,@sem1,2,3,'09:20','10:05',N'202',@eff),(@c11A2,@subCs,  @tId09,@sem1,2,4,'10:15','11:00',N'202',@eff),
(@c11A2,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'202',@eff),
-- 11A2 Wed
(@c11A2,@subEng, @tId03,@sem1,3,1,'07:30','08:15',N'202',@eff),(@c11A2,@subLit, @tId02,@sem1,3,2,'08:25','09:10',N'202',@eff),
(@c11A2,@subMath,@tId01,@sem1,3,3,'09:20','10:05',N'202',@eff),(@c11A2,@subPhy, @tId04,@sem1,3,4,'10:15','11:00',N'202',@eff),
(@c11A2,@subBio, @tId06,@sem1,3,5,'11:10','11:55',N'202',@eff),
-- 11A2 Thu
(@c11A2,@subChem,@tId05,@sem1,4,1,'07:30','08:15',N'202',@eff),(@c11A2,@subHis, @tId07,@sem1,4,2,'08:25','09:10',N'202',@eff),
(@c11A2,@subGeo, @tId08,@sem1,4,3,'09:20','10:05',N'202',@eff),(@c11A2,@subCs,  @tId09,@sem1,4,4,'10:15','11:00',N'202',@eff),
(@c11A2,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'202',@eff),
-- 11A2 Fri
(@c11A2,@subEng, @tId03,@sem1,5,1,'07:30','08:15',N'202',@eff),(@c11A2,@subLit, @tId02,@sem1,5,2,'08:25','09:10',N'202',@eff),
(@c11A2,@subMath,@tId01,@sem1,5,3,'09:20','10:05',N'202',@eff),(@c11A2,@subPhy, @tId04,@sem1,5,4,'10:15','11:00',N'202',@eff),
(@c11A2,@subBio, @tId06,@sem1,5,5,'11:10','11:55',N'202',@eff);

-- ── 12b. LESSON SESSIONS (Week of June 8-12, 2026) ────────────
-- Generate actual class sessions from timetable for attendance tracking
-- June 8 = Mon (DayOfWeek=1), June 9 = Tue (DayOfWeek=2), etc.

-- 10A1: Mon Jun 8 (MATH, LIT, ENG, PHY, CHEM)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-08',1,N'101',N'Quadratic equations review',N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-06-08',2,N'101',N'Poetry analysis',N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-06-08',3,N'101',N'Grammar exercises',N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-06-08',4,N'101',N'Newton laws problems',N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-06-08',5,N'101',N'Organic compounds',N'COMPLETED');
DECLARE @ls01 INT = SCOPE_IDENTITY() - 4;
DECLARE @ls02 INT = @ls01 + 1;
DECLARE @ls03 INT = @ls01 + 2;
DECLARE @ls04 INT = @ls01 + 3;
DECLARE @ls05 INT = @ls01 + 4;

-- 10A1: Tue Jun 9 (BIO, HIS, GEO, CS, PE)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-06-09',1,N'101',N'Cell division',N'COMPLETED'),
(@c10A1,@subHis, @tId07,'2026-06-09',2,N'101',N'World War II',N'COMPLETED'),
(@c10A1,@subGeo, @tId08,'2026-06-09',3,N'101',N'Climate zones',N'COMPLETED'),
(@c10A1,@subCs,  @tId09,'2026-06-09',4,N'101',N'Python basics',N'COMPLETED'),
(@c10A1,@subPe,  @tId10,'2026-06-09',5,N'GYM',N'Basketball',N'COMPLETED');
DECLARE @ls06 INT = SCOPE_IDENTITY() - 4;
DECLARE @ls07 INT = @ls06 + 1;
DECLARE @ls08 INT = @ls06 + 2;
DECLARE @ls09 INT = @ls06 + 3;
DECLARE @ls10 INT = @ls06 + 4;

-- 10A1: Wed Jun 10 (MATH, LIT, ENG, PHY, CHEM)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-10',1,N'101',N'Polynomial functions',N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-06-10',2,N'101',N'Essay writing',N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-06-10',3,N'101',N'Reading comprehension',N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-06-10',4,N'101',N'Energy conservation',N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-06-10',5,N'101',N'Acids and bases',N'COMPLETED');
DECLARE @ls11 INT = SCOPE_IDENTITY() - 4;

-- 10A1: Thu Jun 11 (BIO, HIS, GEO, CS, PE)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-06-11',1,N'101',N'Genetics intro',N'COMPLETED'),
(@c10A1,@subHis, @tId07,'2026-06-11',2,N'101',N'Cold War era',N'COMPLETED'),
(@c10A1,@subGeo, @tId08,'2026-06-11',3,N'101',N'Population',N'COMPLETED'),
(@c10A1,@subCs,  @tId09,'2026-06-11',4,N'101',N'Loops and conditions',N'COMPLETED'),
(@c10A1,@subPe,  @tId10,'2026-06-11',5,N'GYM',N'Volleyball',N'COMPLETED');
DECLARE @ls16 INT = SCOPE_IDENTITY() - 4;

-- 10A1: Fri Jun 12 (MATH, LIT, ENG, PHY, CHEM)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-12',1,N'101',N'Trigonometry',N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-06-12',2,N'101',N'Novel discussion',N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-06-12',3,N'101',N'Vocabulary quiz',N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-06-12',4,N'101',N'Wave mechanics',N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-06-12',5,N'101',N'Lab experiment',N'COMPLETED');
DECLARE @ls21 INT = SCOPE_IDENTITY() - 4;

-- ── 12c. ATTENDANCE RECORDS (for 10A1 students, week of Jun 8-12) ──
-- All 4 students in 10A1: @sId01 (Pham Quoc Bao), @sId02, @sId03, @sId04
-- RecordedBy = the teacher who taught that session

-- Mon Jun 8 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls01,@sId01,N'PRESENT',@uT01),(@ls01,@sId02,N'PRESENT',@uT01),(@ls01,@sId03,N'LATE',@uT01),(@ls01,@sId04,N'PRESENT',@uT01),
(@ls02,@sId01,N'PRESENT',@uT02),(@ls02,@sId02,N'PRESENT',@uT02),(@ls02,@sId03,N'PRESENT',@uT02),(@ls02,@sId04,N'ABSENT',@uT02),
(@ls03,@sId01,N'PRESENT',@uT03),(@ls03,@sId02,N'LATE',@uT03),(@ls03,@sId03,N'PRESENT',@uT03),(@ls03,@sId04,N'PRESENT',@uT03),
(@ls04,@sId01,N'PRESENT',@uT04),(@ls04,@sId02,N'PRESENT',@uT04),(@ls04,@sId03,N'PRESENT',@uT04),(@ls04,@sId04,N'PRESENT',@uT04),
(@ls05,@sId01,N'PRESENT',@uT05),(@ls05,@sId02,N'PRESENT',@uT05),(@ls05,@sId03,N'EXCUSED',@uT05),(@ls05,@sId04,N'PRESENT',@uT05);

-- Tue Jun 9 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls06,@sId01,N'PRESENT',@uT06),(@ls06,@sId02,N'PRESENT',@uT06),(@ls06,@sId03,N'PRESENT',@uT06),(@ls06,@sId04,N'PRESENT',@uT06),
(@ls07,@sId01,N'PRESENT',@uT07),(@ls07,@sId02,N'ABSENT',@uT07),(@ls07,@sId03,N'PRESENT',@uT07),(@ls07,@sId04,N'PRESENT',@uT07),
(@ls08,@sId01,N'PRESENT',@uT08),(@ls08,@sId02,N'PRESENT',@uT08),(@ls08,@sId03,N'LATE',@uT08),(@ls08,@sId04,N'PRESENT',@uT08),
(@ls09,@sId01,N'PRESENT',@uT09),(@ls09,@sId02,N'PRESENT',@uT09),(@ls09,@sId03,N'PRESENT',@uT09),(@ls09,@sId04,N'LATE',@uT09),
(@ls10,@sId01,N'PRESENT',@uT10),(@ls10,@sId02,N'PRESENT',@uT10),(@ls10,@sId03,N'PRESENT',@uT10),(@ls10,@sId04,N'PRESENT',@uT10);

-- Wed Jun 10 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls11,@sId01,N'PRESENT',@uT01),(@ls11,@sId02,N'PRESENT',@uT01),(@ls11,@sId03,N'PRESENT',@uT01),(@ls11,@sId04,N'ABSENT',@uT01),
(@ls11+1,@sId01,N'PRESENT',@uT02),(@ls11+1,@sId02,N'LATE',@uT02),(@ls11+1,@sId03,N'PRESENT',@uT02),(@ls11+1,@sId04,N'PRESENT',@uT02),
(@ls11+2,@sId01,N'PRESENT',@uT03),(@ls11+2,@sId02,N'PRESENT',@uT03),(@ls11+2,@sId03,N'PRESENT',@uT03),(@ls11+2,@sId04,N'PRESENT',@uT03),
(@ls11+3,@sId01,N'LATE',@uT04),(@ls11+3,@sId02,N'PRESENT',@uT04),(@ls11+3,@sId03,N'PRESENT',@uT04),(@ls11+3,@sId04,N'PRESENT',@uT04),
(@ls11+4,@sId01,N'PRESENT',@uT05),(@ls11+4,@sId02,N'PRESENT',@uT05),(@ls11+4,@sId03,N'PRESENT',@uT05),(@ls11+4,@sId04,N'EXCUSED',@uT05);

-- Thu Jun 11 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls16,@sId01,N'PRESENT',@uT06),(@ls16,@sId02,N'PRESENT',@uT06),(@ls16,@sId03,N'ABSENT',@uT06),(@ls16,@sId04,N'PRESENT',@uT06),
(@ls16+1,@sId01,N'PRESENT',@uT07),(@ls16+1,@sId02,N'PRESENT',@uT07),(@ls16+1,@sId03,N'PRESENT',@uT07),(@ls16+1,@sId04,N'PRESENT',@uT07),
(@ls16+2,@sId01,N'PRESENT',@uT08),(@ls16+2,@sId02,N'PRESENT',@uT08),(@ls16+2,@sId03,N'PRESENT',@uT08),(@ls16+2,@sId04,N'LATE',@uT08),
(@ls16+3,@sId01,N'PRESENT',@uT09),(@ls16+3,@sId02,N'LATE',@uT09),(@ls16+3,@sId03,N'PRESENT',@uT09),(@ls16+3,@sId04,N'PRESENT',@uT09),
(@ls16+4,@sId01,N'PRESENT',@uT10),(@ls16+4,@sId02,N'PRESENT',@uT10),(@ls16+4,@sId03,N'PRESENT',@uT10),(@ls16+4,@sId04,N'PRESENT',@uT10);

-- Fri Jun 12 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls21,@sId01,N'PRESENT',@uT01),(@ls21,@sId02,N'PRESENT',@uT01),(@ls21,@sId03,N'PRESENT',@uT01),(@ls21,@sId04,N'PRESENT',@uT01),
(@ls21+1,@sId01,N'PRESENT',@uT02),(@ls21+1,@sId02,N'PRESENT',@uT02),(@ls21+1,@sId03,N'PRESENT',@uT02),(@ls21+1,@sId04,N'ABSENT',@uT02),
(@ls21+2,@sId01,N'PRESENT',@uT03),(@ls21+2,@sId02,N'PRESENT',@uT03),(@ls21+2,@sId03,N'LATE',@uT03),(@ls21+2,@sId04,N'PRESENT',@uT03),
(@ls21+3,@sId01,N'PRESENT',@uT04),(@ls21+3,@sId02,N'PRESENT',@uT04),(@ls21+3,@sId03,N'PRESENT',@uT04),(@ls21+3,@sId04,N'PRESENT',@uT04),
(@ls21+4,@sId01,N'PRESENT',@uT05),(@ls21+4,@sId02,N'EXCUSED',@uT05),(@ls21+4,@sId03,N'PRESENT',@uT05),(@ls21+4,@sId04,N'PRESENT',@uT05);

-- ── 12d. CURRENT WEEK SESSIONS (June 15-19, 2026) ─────────────
-- Today is June 16 (Tue). Mon=completed, Tue=in-progress, Wed-Fri=scheduled

-- 10A1: Mon Jun 15 (MATH, LIT, ENG, PHY, CHEM) - all completed
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-15',1,N'101',N'Final review - algebra',N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-06-15',2,N'101',N'Final review - essays',N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-06-15',3,N'101',N'Final review - grammar',N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-06-15',4,N'101',N'Final review - mechanics',N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-06-15',5,N'101',N'Final review - reactions',N'COMPLETED');
DECLARE @lsW2_01 INT = SCOPE_IDENTITY() - 4;

-- 10A1: Tue Jun 16 (BIO, HIS, GEO, CS, PE) - today, partial completed
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-06-16',1,N'101',N'Final review - genetics',N'COMPLETED'),
(@c10A1,@subHis, @tId07,'2026-06-16',2,N'101',N'Final review - modern history',N'COMPLETED'),
(@c10A1,@subGeo, @tId08,'2026-06-16',3,N'101',N'Final review - maps',N'COMPLETED'),
(@c10A1,@subCs,  @tId09,'2026-06-16',4,N'101',N'Final review - algorithms',N'SCHEDULED'),
(@c10A1,@subPe,  @tId10,'2026-06-16',5,N'GYM',N'Sports day prep',N'SCHEDULED');
DECLARE @lsW2_06 INT = SCOPE_IDENTITY() - 4;

-- 10A1: Wed Jun 17 (MATH, LIT, ENG, PHY, CHEM) - scheduled
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-17',1,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-06-17',2,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-06-17',3,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subPhy, @tId04,'2026-06-17',4,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subChem,@tId05,'2026-06-17',5,N'101',N'Semester exam prep',N'SCHEDULED');

-- 10A1: Thu Jun 18 (BIO, HIS, GEO, CS, PE) - scheduled
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-06-18',1,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subHis, @tId07,'2026-06-18',2,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subGeo, @tId08,'2026-06-18',3,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subCs,  @tId09,'2026-06-18',4,N'101',N'Semester exam prep',N'SCHEDULED'),
(@c10A1,@subPe,  @tId10,'2026-06-18',5,N'GYM',N'Sports day',N'SCHEDULED');

-- 10A1: Fri Jun 19 (MATH, LIT, ENG, PHY, CHEM) - scheduled
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-06-19',1,N'101',N'Last day review',N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-06-19',2,N'101',N'Last day review',N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-06-19',3,N'101',N'Last day review',N'SCHEDULED'),
(@c10A1,@subPhy, @tId04,'2026-06-19',4,N'101',N'Last day review',N'SCHEDULED'),
(@c10A1,@subChem,@tId05,'2026-06-19',5,N'101',N'Last day review',N'SCHEDULED');

-- Attendance for Jun 15 (Mon) - completed
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@lsW2_01,@sId01,N'PRESENT',@uT01),(@lsW2_01,@sId02,N'PRESENT',@uT01),(@lsW2_01,@sId03,N'PRESENT',@uT01),(@lsW2_01,@sId04,N'LATE',@uT01),
(@lsW2_01+1,@sId01,N'PRESENT',@uT02),(@lsW2_01+1,@sId02,N'PRESENT',@uT02),(@lsW2_01+1,@sId03,N'LATE',@uT02),(@lsW2_01+1,@sId04,N'PRESENT',@uT02),
(@lsW2_01+2,@sId01,N'PRESENT',@uT03),(@lsW2_01+2,@sId02,N'PRESENT',@uT03),(@lsW2_01+2,@sId03,N'PRESENT',@uT03),(@lsW2_01+2,@sId04,N'PRESENT',@uT03),
(@lsW2_01+3,@sId01,N'PRESENT',@uT04),(@lsW2_01+3,@sId02,N'ABSENT',@uT04),(@lsW2_01+3,@sId03,N'PRESENT',@uT04),(@lsW2_01+3,@sId04,N'PRESENT',@uT04),
(@lsW2_01+4,@sId01,N'PRESENT',@uT05),(@lsW2_01+4,@sId02,N'PRESENT',@uT05),(@lsW2_01+4,@sId03,N'PRESENT',@uT05),(@lsW2_01+4,@sId04,N'PRESENT',@uT05);

-- Attendance for Jun 16 (Tue) - partial (only completed sessions)
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@lsW2_06,@sId01,N'PRESENT',@uT06),(@lsW2_06,@sId02,N'PRESENT',@uT06),(@lsW2_06,@sId03,N'PRESENT',@uT06),(@lsW2_06,@sId04,N'PRESENT',@uT06),
(@lsW2_06+1,@sId01,N'PRESENT',@uT07),(@lsW2_06+1,@sId02,N'LATE',@uT07),(@lsW2_06+1,@sId03,N'PRESENT',@uT07),(@lsW2_06+1,@sId04,N'PRESENT',@uT07);

-- ── 13. SKILL AREAS ───────────────────────────────────────────
INSERT INTO SkillAreas (SubjectId,Code,Name) VALUES
(@subMath,N'MATH_ALG', N'Algebra and Functions'),
(@subMath,N'MATH_GEOM',N'Geometry and Measurement'),
(@subMath,N'MATH_STAT',N'Statistics and Probability'),
(@subLit, N'LIT_ANA',  N'Text Analysis'),
(@subLit, N'LIT_WRIT', N'Essay Writing'),
(@subEng, N'ENG_READ', N'Reading Comprehension'),
(@subEng, N'ENG_WRIT', N'Writing Skills'),
(@subEng, N'ENG_SPEK', N'Speaking and Listening'),
(@subPhy, N'PHY_MECH', N'Mechanics'),
(@subPhy, N'PHY_ELEC', N'Electricity and Magnetism');

-- ── 14. ASSESSMENTS & MARKS ───────────────────────────────────
-- 3 subjects x 3 types x 4 classes = 36 assessments | 4 students each = 144 marks
-- Insert one assessment then immediately insert its marks (uses SCOPE_IDENTITY)

-- ===== 10A1 – MATH =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subMath,@tId01,@sem1,@atQuiz,N'Math Quiz 1',    '2025-10-05',10,0.10,N'COMPLETED');
DECLARE @a10A1_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_MQ,@sId01,9.0,N'Excellent!',@tId01),(@a10A1_MQ,@sId02,8.5,N'Very good.',@tId01),
(@a10A1_MQ,@sId03,7.5,N'Good.',@tId01),     (@a10A1_MQ,@sId04,8.0,N'Good effort.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subMath,@tId01,@sem1,@atMid, N'Math Midterm Sem 1','2025-11-15',10,0.30,N'COMPLETED');
DECLARE @a10A1_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_MM,@sId01,8.5,N'Very good.',@tId01),(@a10A1_MM,@sId02,8.0,N'Good.',@tId01),
(@a10A1_MM,@sId03,7.0,N'Satisfactory.',@tId01),(@a10A1_MM,@sId04,7.5,N'Satisfactory.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subMath,@tId01,@sem1,@atFinal,N'Math Final Sem 1',  '2026-01-10',10,0.60,N'COMPLETED');
DECLARE @a10A1_MF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_MF,@sId01,8.0,N'Well done.',@tId01),(@a10A1_MF,@sId02,8.5,N'Excellent.',@tId01),
(@a10A1_MF,@sId03,7.5,N'Good progress.',@tId01),(@a10A1_MF,@sId04,8.0,N'Good.',@tId01);

-- ===== 10A1 – LIT =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subLit,@tId02,@sem1,@atQuiz, N'Lit Quiz 1',      '2025-10-07',10,0.10,N'COMPLETED');
DECLARE @a10A1_LQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_LQ,@sId01,8.5,N'Good analysis.',@tId02),(@a10A1_LQ,@sId02,9.0,N'Excellent!',@tId02),
(@a10A1_LQ,@sId03,8.0,N'Good.',@tId02),          (@a10A1_LQ,@sId04,7.5,N'Satisfactory.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subLit,@tId02,@sem1,@atMid,  N'Lit Midterm Sem 1','2025-11-17',10,0.30,N'COMPLETED');
DECLARE @a10A1_LM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_LM,@sId01,8.0,N'Well structured.',@tId02),(@a10A1_LM,@sId02,8.5,N'Very good.',@tId02),
(@a10A1_LM,@sId03,7.5,N'Good.',@tId02),            (@a10A1_LM,@sId04,7.0,N'Needs more depth.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subLit,@tId02,@sem1,@atFinal,N'Lit Final Sem 1',  '2026-01-12',10,0.60,N'COMPLETED');
DECLARE @a10A1_LF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_LF,@sId01,8.5,N'Excellent essay.',@tId02),(@a10A1_LF,@sId02,9.0,N'Outstanding!',@tId02),
(@a10A1_LF,@sId03,8.0,N'Well done.',@tId02),       (@a10A1_LF,@sId04,7.5,N'Good effort.',@tId02);

-- ===== 10A1 – ENG =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subEng,@tId03,@sem1,@atQuiz, N'English Quiz 1',      '2025-10-09',10,0.10,N'COMPLETED');
DECLARE @a10A1_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_EQ,@sId01,7.5,N'Good.',@tId03),(@a10A1_EQ,@sId02,8.5,N'Very good.',@tId03),
(@a10A1_EQ,@sId03,8.0,N'Good.',@tId03),(@a10A1_EQ,@sId04,7.0,N'Needs practice.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subEng,@tId03,@sem1,@atMid,  N'English Midterm Sem 1','2025-11-19',10,0.30,N'COMPLETED');
DECLARE @a10A1_EM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_EM,@sId01,7.0,N'Satisfactory.',@tId03),(@a10A1_EM,@sId02,8.0,N'Good.',@tId03),
(@a10A1_EM,@sId03,7.5,N'Good.',@tId03),         (@a10A1_EM,@sId04,6.5,N'More reading needed.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A1,@subEng,@tId03,@sem1,@atFinal,N'English Final Sem 1',  '2026-01-14',10,0.60,N'COMPLETED');
DECLARE @a10A1_EF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A1_EF,@sId01,7.5,N'Good improvement.',@tId03),(@a10A1_EF,@sId02,8.5,N'Excellent.',@tId03),
(@a10A1_EF,@sId03,8.0,N'Very good.',@tId03),        (@a10A1_EF,@sId04,7.0,N'Good effort.',@tId03);

-- ===== 10A2 – MATH =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subMath,@tId01,@sem1,@atQuiz, N'Math Quiz 1',    '2025-10-06',10,0.10,N'COMPLETED');
DECLARE @a10A2_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_MQ,@sId05,8.5,N'Very good.',@tId01),(@a10A2_MQ,@sId06,7.5,N'Good.',@tId01),
(@a10A2_MQ,@sId07,6.5,N'Needs practice.',@tId01),(@a10A2_MQ,@sId08,9.0,N'Excellent!',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subMath,@tId01,@sem1,@atMid, N'Math Midterm Sem 1','2025-11-16',10,0.30,N'COMPLETED');
DECLARE @a10A2_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_MM,@sId05,8.0,N'Good.',@tId01),(@a10A2_MM,@sId06,7.0,N'Satisfactory.',@tId01),
(@a10A2_MM,@sId07,6.0,N'Review chapter 2.',@tId01),(@a10A2_MM,@sId08,8.5,N'Very good.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subMath,@tId01,@sem1,@atFinal,N'Math Final Sem 1',  '2026-01-11',10,0.60,N'COMPLETED');
DECLARE @a10A2_MF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_MF,@sId05,8.0,N'Solid.',@tId01),(@a10A2_MF,@sId06,7.5,N'Good.',@tId01),
(@a10A2_MF,@sId07,6.5,N'Improved.',@tId01),(@a10A2_MF,@sId08,9.0,N'Outstanding!',@tId01);

-- ===== 10A2 – LIT =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subLit,@tId02,@sem1,@atQuiz, N'Lit Quiz 1',      '2025-10-08',10,0.10,N'COMPLETED');
DECLARE @a10A2_LQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_LQ,@sId05,7.5,N'Good.',@tId02),(@a10A2_LQ,@sId06,8.0,N'Very good.',@tId02),
(@a10A2_LQ,@sId07,7.0,N'Satisfactory.',@tId02),(@a10A2_LQ,@sId08,8.5,N'Excellent.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subLit,@tId02,@sem1,@atMid,  N'Lit Midterm Sem 1','2025-11-18',10,0.30,N'COMPLETED');
DECLARE @a10A2_LM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_LM,@sId05,7.0,N'Good.',@tId02),(@a10A2_LM,@sId06,7.5,N'Good.',@tId02),
(@a10A2_LM,@sId07,6.5,N'More effort.',@tId02),(@a10A2_LM,@sId08,8.0,N'Very good.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subLit,@tId02,@sem1,@atFinal,N'Lit Final Sem 1',  '2026-01-13',10,0.60,N'COMPLETED');
DECLARE @a10A2_LF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_LF,@sId05,7.5,N'Good.',@tId02),(@a10A2_LF,@sId06,8.0,N'Very good.',@tId02),
(@a10A2_LF,@sId07,7.0,N'Satisfactory.',@tId02),(@a10A2_LF,@sId08,8.5,N'Excellent.',@tId02);

-- ===== 10A2 – ENG =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subEng,@tId03,@sem1,@atQuiz, N'English Quiz 1',      '2025-10-10',10,0.10,N'COMPLETED');
DECLARE @a10A2_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_EQ,@sId05,9.0,N'Excellent!',@tId03),(@a10A2_EQ,@sId06,7.5,N'Good.',@tId03),
(@a10A2_EQ,@sId07,6.0,N'Needs work.',@tId03),(@a10A2_EQ,@sId08,8.0,N'Very good.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subEng,@tId03,@sem1,@atMid,  N'English Midterm Sem 1','2025-11-20',10,0.30,N'COMPLETED');
DECLARE @a10A2_EM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_EM,@sId05,8.5,N'Very good.',@tId03),(@a10A2_EM,@sId06,7.0,N'Good.',@tId03),
(@a10A2_EM,@sId07,5.5,N'Review grammar.',@tId03),(@a10A2_EM,@sId08,7.5,N'Good.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c10A2,@subEng,@tId03,@sem1,@atFinal,N'English Final Sem 1',  '2026-01-15',10,0.60,N'COMPLETED');
DECLARE @a10A2_EF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a10A2_EF,@sId05,9.0,N'Outstanding!',@tId03),(@a10A2_EF,@sId06,7.5,N'Good.',@tId03),
(@a10A2_EF,@sId07,6.0,N'Good improvement.',@tId03),(@a10A2_EF,@sId08,8.0,N'Very good.',@tId03);

-- ===== 11A1 – MATH =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subMath,@tId01,@sem1,@atQuiz, N'Math Quiz 1',    '2025-10-05',10,0.10,N'COMPLETED');
DECLARE @a11A1_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_MQ,@sId09,9.5,N'Perfect!',@tId01),(@a11A1_MQ,@sId10,8.0,N'Good.',@tId01),
(@a11A1_MQ,@sId11,7.5,N'Satisfactory.',@tId01),(@a11A1_MQ,@sId12,7.0,N'Needs practice.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subMath,@tId01,@sem1,@atMid, N'Math Midterm Sem 1','2025-11-15',10,0.30,N'COMPLETED');
DECLARE @a11A1_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_MM,@sId09,9.0,N'Excellent.',@tId01),(@a11A1_MM,@sId10,7.5,N'Good.',@tId01),
(@a11A1_MM,@sId11,7.0,N'Satisfactory.',@tId01),(@a11A1_MM,@sId12,6.5,N'Review derivatives.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subMath,@tId01,@sem1,@atFinal,N'Math Final Sem 1',  '2026-01-10',10,0.60,N'COMPLETED');
DECLARE @a11A1_MF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_MF,@sId09,9.0,N'Top student.',@tId01),(@a11A1_MF,@sId10,8.0,N'Well done.',@tId01),
(@a11A1_MF,@sId11,7.5,N'Good.',@tId01),(@a11A1_MF,@sId12,7.0,N'Keep improving.',@tId01);

-- ===== 11A1 – LIT =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subLit,@tId02,@sem1,@atQuiz, N'Lit Quiz 1',      '2025-10-07',10,0.10,N'COMPLETED');
DECLARE @a11A1_LQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_LQ,@sId09,8.0,N'Good insight.',@tId02),(@a11A1_LQ,@sId10,8.5,N'Very good.',@tId02),
(@a11A1_LQ,@sId11,9.0,N'Excellent!',@tId02),   (@a11A1_LQ,@sId12,7.5,N'Good.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subLit,@tId02,@sem1,@atMid,  N'Lit Midterm Sem 1','2025-11-17',10,0.30,N'COMPLETED');
DECLARE @a11A1_LM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_LM,@sId09,7.5,N'Good.',@tId02),(@a11A1_LM,@sId10,8.0,N'Very good.',@tId02),
(@a11A1_LM,@sId11,8.5,N'Excellent.',@tId02),(@a11A1_LM,@sId12,7.0,N'Satisfactory.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subLit,@tId02,@sem1,@atFinal,N'Lit Final Sem 1',  '2026-01-12',10,0.60,N'COMPLETED');
DECLARE @a11A1_LF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_LF,@sId09,8.0,N'Well done.',@tId02),(@a11A1_LF,@sId10,8.5,N'Very good.',@tId02),
(@a11A1_LF,@sId11,9.0,N'Outstanding!',@tId02),(@a11A1_LF,@sId12,7.5,N'Good.',@tId02);

-- ===== 11A1 – ENG =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subEng,@tId03,@sem1,@atQuiz, N'English Quiz 1',      '2025-10-09',10,0.10,N'COMPLETED');
DECLARE @a11A1_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_EQ,@sId09,8.5,N'Very good.',@tId03),(@a11A1_EQ,@sId10,7.5,N'Good.',@tId03),
(@a11A1_EQ,@sId11,8.0,N'Good.',@tId03),     (@a11A1_EQ,@sId12,7.0,N'Satisfactory.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subEng,@tId03,@sem1,@atMid,  N'English Midterm Sem 1','2025-11-19',10,0.30,N'COMPLETED');
DECLARE @a11A1_EM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_EM,@sId09,8.0,N'Good.',@tId03),(@a11A1_EM,@sId10,7.0,N'Satisfactory.',@tId03),
(@a11A1_EM,@sId11,7.5,N'Good.',@tId03),  (@a11A1_EM,@sId12,6.5,N'More reading.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A1,@subEng,@tId03,@sem1,@atFinal,N'English Final Sem 1',  '2026-01-14',10,0.60,N'COMPLETED');
DECLARE @a11A1_EF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A1_EF,@sId09,8.5,N'Excellent.',@tId03),(@a11A1_EF,@sId10,7.5,N'Good.',@tId03),
(@a11A1_EF,@sId11,8.0,N'Very good.',@tId03),(@a11A1_EF,@sId12,7.0,N'Good effort.',@tId03);

-- ===== 11A2 – MATH =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subMath,@tId01,@sem1,@atQuiz, N'Math Quiz 1',    '2025-10-06',10,0.10,N'COMPLETED');
DECLARE @a11A2_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_MQ,@sId13,8.0,N'Good.',@tId01),(@a11A2_MQ,@sId14,9.0,N'Excellent!',@tId01),
(@a11A2_MQ,@sId15,6.5,N'Needs practice.',@tId01),(@a11A2_MQ,@sId16,8.5,N'Very good.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subMath,@tId01,@sem1,@atMid, N'Math Midterm Sem 1','2025-11-16',10,0.30,N'COMPLETED');
DECLARE @a11A2_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_MM,@sId13,7.5,N'Good.',@tId01),(@a11A2_MM,@sId14,8.5,N'Very good.',@tId01),
(@a11A2_MM,@sId15,6.0,N'Review algebra.',@tId01),(@a11A2_MM,@sId16,8.0,N'Well done.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subMath,@tId01,@sem1,@atFinal,N'Math Final Sem 1',  '2026-01-11',10,0.60,N'COMPLETED');
DECLARE @a11A2_MF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_MF,@sId13,8.0,N'Solid.',@tId01),(@a11A2_MF,@sId14,9.0,N'Outstanding!',@tId01),
(@a11A2_MF,@sId15,6.5,N'Improved.',@tId01),(@a11A2_MF,@sId16,8.5,N'Excellent.',@tId01);

-- ===== 11A2 – LIT =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subLit,@tId02,@sem1,@atQuiz, N'Lit Quiz 1',      '2025-10-08',10,0.10,N'COMPLETED');
DECLARE @a11A2_LQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_LQ,@sId13,9.0,N'Excellent!',@tId02),(@a11A2_LQ,@sId14,8.0,N'Good.',@tId02),
(@a11A2_LQ,@sId15,6.5,N'Needs more reading.',@tId02),(@a11A2_LQ,@sId16,8.5,N'Very good.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subLit,@tId02,@sem1,@atMid,  N'Lit Midterm Sem 1','2025-11-18',10,0.30,N'COMPLETED');
DECLARE @a11A2_LM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_LM,@sId13,8.5,N'Very good.',@tId02),(@a11A2_LM,@sId14,7.5,N'Good.',@tId02),
(@a11A2_LM,@sId15,6.0,N'Read more.',@tId02),(@a11A2_LM,@sId16,8.0,N'Well done.',@tId02);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subLit,@tId02,@sem1,@atFinal,N'Lit Final Sem 1',  '2026-01-13',10,0.60,N'COMPLETED');
DECLARE @a11A2_LF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_LF,@sId13,9.0,N'Outstanding!',@tId02),(@a11A2_LF,@sId14,8.0,N'Good.',@tId02),
(@a11A2_LF,@sId15,6.5,N'Decent effort.',@tId02),(@a11A2_LF,@sId16,8.5,N'Excellent.',@tId02);

-- ===== 11A2 – ENG =====
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subEng,@tId03,@sem1,@atQuiz, N'English Quiz 1',      '2025-10-10',10,0.10,N'COMPLETED');
DECLARE @a11A2_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_EQ,@sId13,7.5,N'Good.',@tId03),(@a11A2_EQ,@sId14,8.5,N'Very good.',@tId03),
(@a11A2_EQ,@sId15,6.0,N'Needs practice.',@tId03),(@a11A2_EQ,@sId16,7.0,N'Satisfactory.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subEng,@tId03,@sem1,@atMid,  N'English Midterm Sem 1','2025-11-20',10,0.30,N'COMPLETED');
DECLARE @a11A2_EM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_EM,@sId13,7.0,N'Good.',@tId03),(@a11A2_EM,@sId14,8.0,N'Very good.',@tId03),
(@a11A2_EM,@sId15,5.5,N'More practice.',@tId03),(@a11A2_EM,@sId16,7.5,N'Good.',@tId03);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c11A2,@subEng,@tId03,@sem1,@atFinal,N'English Final Sem 1',  '2026-01-15',10,0.60,N'COMPLETED');
DECLARE @a11A2_EF INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a11A2_EF,@sId13,7.5,N'Good improvement.',@tId03),(@a11A2_EF,@sId14,8.5,N'Excellent.',@tId03),
(@a11A2_EF,@sId15,6.0,N'Keep practicing.',@tId03),  (@a11A2_EF,@sId16,7.5,N'Good.',@tId03);

-- ── 15. STUDY RESOURCES ───────────────────────────────────────
INSERT INTO StudyResources(SubjectId,ClassId,UploadedBy,Title,Description,ResourceType,FileUrl,Visibility,CreatedAt) VALUES
(@subMath,@c10A1,@uT01,N'Math Ch.1 - Functions Notes',   N'Lecture notes: domain, range, composition.',         N'PDF',     N'https://files.estudiez.edu.vn/math/ch1-functions.pdf',     N'CLASS_ONLY',SYSDATETIME()),
(@subMath,@c10A1,@uT01,N'Quadratic Practice Set',         N'50 exercises with worked solutions.',                N'PDF',     N'https://files.estudiez.edu.vn/math/quadratic-practice.pdf',N'CLASS_ONLY',SYSDATETIME()),
(@subMath,NULL,  @uT01,N'Khan Academy - Algebra',         N'Free algebra course (external).',                    N'LINK',    N'https://www.khanacademy.org/math/algebra',                  N'SCHOOL',    SYSDATETIME()),
(@subMath,@c11A1,@uT01,N'Calculus Introduction (G11)',    N'Limits, derivatives, integrals overview.',           N'PDF',     N'https://files.estudiez.edu.vn/math/calculus-intro.pdf',    N'CLASS_ONLY',SYSDATETIME()),
(@subLit, @c10A1,@uT02,N'Poetry Analysis Guide',          N'Techniques for analysing Vietnamese poetry.',        N'PDF',     N'https://files.estudiez.edu.vn/lit/poetry-analysis.pdf',   N'CLASS_ONLY',SYSDATETIME()),
(@subLit, @c11A1,@uT02,N'Novel Study - Dong Chi',         N'Notes on Chinh Huu poem.',                          N'DOCUMENT',N'https://files.estudiez.edu.vn/lit/dongchi-notes.docx',   N'CLASS_ONLY',SYSDATETIME()),
(@subLit, NULL,  @uT02,N'Essay Writing Handbook',         N'Structure and language for literary essays.',        N'PDF',     N'https://files.estudiez.edu.vn/lit/essay-handbook.pdf',    N'SCHOOL',    SYSDATETIME()),
(@subEng, @c10A1,@uT03,N'Grammar Review - All Tenses',   N'Summary sheet with examples and exercises.',         N'PDF',     N'https://files.estudiez.edu.vn/eng/grammar-tenses.pdf',    N'CLASS_ONLY',SYSDATETIME()),
(@subEng, @c10A1,@uT03,N'Listening Unit 3 - Technology', N'Audio exercises for Unit 3.',                        N'VIDEO',   N'https://files.estudiez.edu.vn/eng/listening-unit3.mp4',   N'CLASS_ONLY',SYSDATETIME()),
(@subEng, NULL,  @uT03,N'BBC Learning English',           N'Free English lessons (external).',                   N'LINK',    N'https://www.bbc.co.uk/learningenglish',                     N'SCHOOL',    SYSDATETIME()),
(@subPhy, @c10A1,@uT04,N'Mechanics - Newtons Laws',       N'Notes and practice problems.',                       N'PDF',     N'https://files.estudiez.edu.vn/phy/mechanics.pdf',          N'CLASS_ONLY',SYSDATETIME()),
(@subPhy, @c11A1,@uT04,N'Electricity Fundamentals',       N'Ohms law, circuits, power.',                        N'PDF',     N'https://files.estudiez.edu.vn/phy/electricity.pdf',        N'CLASS_ONLY',SYSDATETIME()),
(@subChem,@c10A1,@uT05,N'Periodic Table Guide',           N'Groups, periods, trends explained.',                 N'PDF',     N'https://files.estudiez.edu.vn/chem/periodic-table.pdf',   N'CLASS_ONLY',SYSDATETIME()),
(@subBio, @c10A1,@uT06,N'Cell Biology Summary',           N'Cell structure, organelles, functions.',             N'PDF',     N'https://files.estudiez.edu.vn/bio/cell-biology.pdf',       N'CLASS_ONLY',SYSDATETIME()),
(@subHis, NULL,  @uT07,N'Vietnamese Revolution 1945',     N'Key events and analysis.',                           N'DOCUMENT',N'https://files.estudiez.edu.vn/his/revolution-1945.docx', N'SCHOOL',    SYSDATETIME()),
(@subGeo, NULL,  @uT08,N'Physical Geography of Vietnam',  N'Rivers, mountains, climate zones.',                  N'PDF',     N'https://files.estudiez.edu.vn/geo/vn-geography.pdf',       N'SCHOOL',    SYSDATETIME()),
(@subCs,  @c10A1,@uT09,N'Scratch Programming Basics',     N'Visual programming for beginners.',                  N'LINK',    N'https://scratch.mit.edu',                                   N'CLASS_ONLY',SYSDATETIME()),
(@subCs,  @c11A1,@uT09,N'Python Introduction',            N'Variables, loops, functions intro.',                 N'PDF',     N'https://files.estudiez.edu.vn/cs/python-intro.pdf',        N'CLASS_ONLY',SYSDATETIME());

-- ── 16. CHAT GROUPS (4 classes x 2 types = 8) ────────────────
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c10A1,@syId,N'STUDENT_TEACHER',N'10A1 - Students & Teacher Chat',SYSDATETIME());
DECLARE @cg1 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c10A1,@syId,N'PARENT_TEACHER', N'10A1 - Parents & Teacher Chat', SYSDATETIME());
DECLARE @cg2 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c10A2,@syId,N'STUDENT_TEACHER',N'10A2 - Students & Teacher Chat',SYSDATETIME());
DECLARE @cg3 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c10A2,@syId,N'PARENT_TEACHER', N'10A2 - Parents & Teacher Chat', SYSDATETIME());
DECLARE @cg4 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c11A1,@syId,N'STUDENT_TEACHER',N'11A1 - Students & Teacher Chat',SYSDATETIME());
DECLARE @cg5 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c11A1,@syId,N'PARENT_TEACHER', N'11A1 - Parents & Teacher Chat', SYSDATETIME());
DECLARE @cg6 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c11A2,@syId,N'STUDENT_TEACHER',N'11A2 - Students & Teacher Chat',SYSDATETIME());
DECLARE @cg7 INT = SCOPE_IDENTITY();
INSERT INTO ChatGroups(ClassId,SchoolYearId,GroupType,Name,CreatedAt)
    VALUES(@c11A2,@syId,N'PARENT_TEACHER', N'11A2 - Parents & Teacher Chat', SYSDATETIME());
DECLARE @cg8 INT = SCOPE_IDENTITY();

-- Members
INSERT INTO ChatGroupMembers(ChatGroupId,UserId) VALUES
(@cg1,@uT01),(@cg1,@uS01),(@cg1,@uS02),(@cg1,@uS03),(@cg1,@uS04),
(@cg2,@uT01),(@cg2,@uP01),(@cg2,@uP02),(@cg2,@uP03),(@cg2,@uP04),
(@cg3,@uT04),(@cg3,@uS05),(@cg3,@uS06),(@cg3,@uS07),(@cg3,@uS08),
(@cg4,@uT04),(@cg4,@uP05),(@cg4,@uP06),(@cg4,@uP07),(@cg4,@uP08),
(@cg5,@uT02),(@cg5,@uS09),(@cg5,@uS10),(@cg5,@uS11),(@cg5,@uS12),
(@cg6,@uT02),(@cg6,@uP09),(@cg6,@uP10),(@cg6,@uP11),(@cg6,@uP12),
(@cg7,@uT03),(@cg7,@uS13),(@cg7,@uS14),(@cg7,@uS15),(@cg7,@uS16),
(@cg8,@uT03),(@cg8,@uP13),(@cg8,@uP14),(@cg8,@uP15),(@cg8,@uP16);

-- Messages
INSERT INTO ChatMessages(ChatGroupId,SenderUserId,MessageText,CreatedAt) VALUES
(@cg1,@uT01,N'Hello class 10A1! Check the updated timetable for next week.', DATEADD(DAY,-20,SYSDATETIME())),
(@cg1,@uS01,N'Thank you teacher! I saw Math moved to Period 2 on Wednesday.', DATEADD(DAY,-20,SYSDATETIME())),
(@cg1,@uT01,N'Correct Bao. Also complete exercise set 3 before Monday.',      DATEADD(DAY,-19,SYSDATETIME())),
(@cg2,@uT01,N'Dear parents, midterm results for Math are posted in the portal. Please review.', DATEADD(DAY,-15,SYSDATETIME())),
(@cg2,@uP01,N'Thank you teacher. Bao improved this term, very happy!',        DATEADD(DAY,-14,SYSDATETIME())),
(@cg3,@uT04,N'10A2 students: Physics lab session moved to Thursday P3, Room 104.', DATEADD(DAY,-18,SYSDATETIME())),
(@cg3,@uS08,N'Noted teacher, will bring safety goggles.',                     DATEADD(DAY,-18,SYSDATETIME())),
(@cg5,@uT02,N'Class 11A1, literature essays are due this Friday. No extensions.', DATEADD(DAY,-10,SYSDATETIME())),
(@cg5,@uS09,N'Teacher, can we submit by email if we are unwell?',             DATEADD(DAY,-10,SYSDATETIME())),
(@cg5,@uT02,N'Yes, email is fine as long as it is before 23:59 Friday.',      DATEADD(DAY,-9,SYSDATETIME())),
(@cg6,@uP09,N'Hi teacher, Le Thi Hoa was absent due to illness. Returns tomorrow.', DATEADD(DAY,-7,SYSDATETIME())),
(@cg6,@uT02,N'Thank you. Please send the doctors note when she returns.',    DATEADD(DAY,-7,SYSDATETIME())),
(@cg7,@uT03,N'11A2, speaking assessment is 8-9 January. Slots on classroom board.', DATEADD(DAY,-5,SYSDATETIME())),
(@cg7,@uS14,N'Teacher, what topic should we prepare?',                        DATEADD(DAY,-5,SYSDATETIME())),
(@cg7,@uT03,N'Topic: "Technology in everyday life". Prepare 3-4 minutes.',    DATEADD(DAY,-4,SYSDATETIME()));

-- ── 17. NOTIFICATIONS ─────────────────────────────────────────
INSERT INTO Notifications(SenderUserId,Title,Content,Category,TargetType,TargetId,CreatedAt) VALUES
(@uAdmin,N'Welcome to eStudiez 2025-2026',
    N'The school portal is now open for the new academic year. Students and parents can view timetables, results, and resources.',
    N'GENERAL',N'ALL',NULL,DATEADD(DAY,-90,SYSDATETIME())),
(@uT01,N'Math Timetable Update - 10A1',
    N'Math class for 10A1 has moved from Period 1 to Period 2 on Wednesdays, effective 15 October 2025.',
    N'TIMETABLE',N'CLASS',CAST(@c10A1 AS NVARCHAR(20)),DATEADD(DAY,-60,SYSDATETIME())),
(@uT02,N'Literature Essay Due - 11A1',
    N'Reminder: Your literary analysis essay on Dong Chi is due this Friday. Submit to the teacher office.',
    N'ACADEMIC',N'CLASS',CAST(@c11A1 AS NVARCHAR(20)),DATEADD(DAY,-10,SYSDATETIME())),
(@uT03,N'English Speaking Test - 11A2',
    N'Individual speaking assessments will be held on 8-9 January 2026. Check the classroom board for your time slot.',
    N'EXAM',N'CLASS',CAST(@c11A2 AS NVARCHAR(20)),DATEADD(DAY,-5,SYSDATETIME())),
(@uAdmin,N'School Closed - National Holiday 30 April',
    N'The school will be closed on 30 April 2026 (Liberation Day). Classes resume on 2 May 2026.',
    N'HOLIDAY',N'ALL',NULL,DATEADD(DAY,-3,SYSDATETIME())),
(@uAdmin,N'Parent-Teacher Meeting - 25 January 2026',
    N'A parent-teacher meeting is scheduled for 25 January 2026, 08:00-11:00 in the school hall. All parents are invited.',
    N'MEETING',N'PARENT',NULL,DATEADD(DAY,-12,SYSDATETIME())),
(@uAdmin,N'Semester 1 Results Released',
    N'Semester 1 final exam results are now available in the eStudiez portal under the Results section.',
    N'ACADEMIC',N'ALL',NULL,DATEADD(DAY,-8,SYSDATETIME())),
(@uAdmin,N'Annual Sports Day - 6 December 2025',
    N'Register your team for football, volleyball, badminton and athletics by 25 November 2025 at the PE office.',
    N'EVENT',N'STUDENT',NULL,DATEADD(DAY,-30,SYSDATETIME()));

-- ── 18. NEWS POSTS ────────────────────────────────────────────
INSERT INTO NewsPosts(AuthorUserId,Category,Title,Slug,Content,Status,PublishedAt,CreatedAt,UpdatedAt) VALUES
(@uAdmin,N'ANNOUNCEMENT',N'Welcome to the 2025-2026 Academic Year',N'welcome-2025-2026',
N'Dear students, parents, and teachers,

We warmly welcome everyone to the new academic year 2025-2026. This year our school continues its commitment to excellence in education, offering a rich curriculum, experienced teachers, and a supportive learning environment.

Key dates:
- First day of classes: 5 September 2025
- Semester 1 midterms: November 2025
- Semester 1 finals: January 2026
- School anniversary: 20 November 2025

Wishing all students a productive and successful year!

The Board of Management',
N'PUBLISHED',DATEADD(DAY,-90,SYSDATETIME()),DATEADD(DAY,-90,SYSDATETIME()),DATEADD(DAY,-90,SYSDATETIME())),

(@uAdmin,N'CLASS_LIST',N'Official Class Lists - School Year 2025-2026',N'class-list-2025-2026',
N'The official class lists for 2025-2026 have been finalised.

Grade 10:
- Class 10A1 | Homeroom: Nguyen Van Minh (Mathematics) | Room 101
  Students: Pham Quoc Bao, Nguyen Thi Mai, Tran Van Duc, Phan Ngoc Linh
- Class 10A2 | Homeroom: Pham Duc Khanh (Physics) | Room 102
  Students: Le Thanh Hung, Ho Thi Thuy, Tran Quoc An, Nguyen Dieu Vy

Grade 11:
- Class 11A1 | Homeroom: Tran Thi Lan (Literature) | Room 201
  Students: Le Thi Hoa, Vo Minh Khoa, Nguyen Quoc Lan, Bui Duc Minh
- Class 11A2 | Homeroom: Le Hoang Nam (English) | Room 202
  Students: Pham Hong Thu, Dang Thanh Long, Bui Van Nam, Le Thi Huong

Students not on any list should contact the school office before 10 September 2025.',
N'PUBLISHED',DATEADD(DAY,-88,SYSDATETIME()),DATEADD(DAY,-88,SYSDATETIME()),DATEADD(DAY,-88,SYSDATETIME())),

(@uAdmin,N'EVENT',N'Vietnamese Teachers Day Celebration - 20 November 2025',N'teachers-day-2025',
N'Our school will celebrate Vietnamese Teachers Day on 20 November 2025 with a special ceremony and cultural performances.

Schedule:
- 07:30: Students gather in the school courtyard
- 08:00: Opening ceremony and speeches
- 08:30: Cultural performances (music, dance, poetry)
- 09:30: Class visits and gift presentations to teachers

All students must wear full school uniform. Parents are welcome to attend.',
N'PUBLISHED',DATEADD(DAY,-30,SYSDATETIME()),DATEADD(DAY,-30,SYSDATETIME()),DATEADD(DAY,-30,SYSDATETIME())),

(@uAdmin,N'ANNOUNCEMENT',N'Midterm Examination Schedule - Semester 1 2025',N'midterm-schedule-s1-2025',
N'The midterm examination schedule for Semester 1 (2025-2026) has been confirmed.

Examination Period: 10-20 November 2025

Grade 10:
- Mathematics  | 10 Nov | P1-P2 | Rooms 101 & 102
- Literature   | 11 Nov | P1-P2 | Rooms 101 & 102
- English      | 13 Nov | P3-P4 | Rooms 101 & 102
- Physics      | 17 Nov | P1-P2 | Rooms 101 & 102

Grade 11:
- Mathematics  | 10 Nov | P3-P4 | Rooms 201 & 202
- Literature   | 11 Nov | P3-P4 | Rooms 201 & 202
- English      | 13 Nov | P1-P2 | Rooms 201 & 202

Students must bring their student ID. Electronic devices are prohibited. Results within 7 working days.',
N'PUBLISHED',DATEADD(DAY,-45,SYSDATETIME()),DATEADD(DAY,-45,SYSDATETIME()),DATEADD(DAY,-45,SYSDATETIME())),

(@uAdmin,N'EVENT',N'Annual Sports Day - 6 December 2025',N'sports-day-2025',
N'Get ready for our Annual Sports Day on 6 December 2025!

Events:
- Football (5-a-side, boys)
- Volleyball (mixed)
- 100m sprint and 4x100m relay
- Badminton (singles and doubles)

Registration deadline: 25 November 2025 at the Physical Education office.

Prizes for top 3 teams in each event. Overall winning class receives the Principal Trophy.',
N'PUBLISHED',DATEADD(DAY,-20,SYSDATETIME()),DATEADD(DAY,-20,SYSDATETIME()),DATEADD(DAY,-20,SYSDATETIME())),

(@uAdmin,N'ANNOUNCEMENT',N'Semester 1 Final Results Now Available',N'sem1-results-2025',
N'Semester 1 final examination results are now available in the eStudiez portal.

Log in and navigate to the Results section to view your scores. Parents can also view through the Parent portal.

If you believe there is an error, contact your subject teacher within 5 working days.

Congratulations to all students on your hard work this semester!',
N'PUBLISHED',DATEADD(DAY,-8,SYSDATETIME()),DATEADD(DAY,-8,SYSDATETIME()),DATEADD(DAY,-8,SYSDATETIME())),

(@uAdmin,N'ANNOUNCEMENT',N'Semester 2 Begins - 20 January 2026',N'semester-2-start-2026',
N'Semester 2 commences on Monday 20 January 2026.

Students are reminded to:
1. Return with complete uniforms and required materials.
2. Check the updated Semester 2 timetable on the portal.
3. Collect outstanding Semester 1 results from your homeroom teacher.

The school canteen and library will reopen on 20 January 2026.',
N'PUBLISHED',DATEADD(DAY,-10,SYSDATETIME()),DATEADD(DAY,-10,SYSDATETIME()),DATEADD(DAY,-10,SYSDATETIME())),

(@uAdmin,N'GENERAL',N'Library New Arrivals - January 2026',N'library-new-arrivals-jan-2026',
N'The school library has received a new book collection for January 2026.

Science & Technology:
- Physics for the 21st Century (updated edition)
- Introduction to Data Science (beginner friendly)

Literature:
- Selected works of contemporary Vietnamese authors
- World Short Stories Anthology (bilingual Vietnamese-English edition)

Students may borrow up to 3 books for 2 weeks. Visit the library during recess or after school.',
N'PUBLISHED',DATEADD(DAY,-5,SYSDATETIME()),DATEADD(DAY,-5,SYSDATETIME()),DATEADD(DAY,-5,SYSDATETIME()));

-- ── 19. REGISTRATION REQUESTS ─────────────────────────────────
INSERT INTO RegistrationRequests(FullName,Email,Phone,RoleRequested,Message,Status,ReviewedBy,ReviewNotes,ReviewedAt,CreatedAt) VALUES
(N'Do Thi Thuy',     N'thuy.dt@gmail.com', N'0988001001',N'student',N'I would like my daughter to enroll in Grade 10 for 2025-2026.',N'PENDING', NULL,      NULL,                         NULL,                          DATEADD(DAY,-15,SYSDATETIME())),
(N'Bui Van Hung',    N'hung.bv@gmail.com', N'0988001002',N'parent', N'I am the parent of Bui Thi Nhi. I want to register as a parent.',N'PENDING',NULL,      NULL,                         NULL,                          DATEADD(DAY,-12,SYSDATETIME())),
(N'Cao Ngoc Linh',   N'linh.cn@gmail.com', N'0988001003',N'teacher',N'Physics teacher, 5 years experience. Interested in joining.',  N'APPROVED',@uAdmin,N'Credentials verified. Welcome!',DATEADD(DAY,-8,SYSDATETIME()), DATEADD(DAY,-10,SYSDATETIME())),
(N'Nguyen Phuoc Loc',N'loc.np@gmail.com',  N'0988001004',N'student',N'Transfer student from Da Nang, Grade 11. Documents attached.',  N'PENDING', NULL,      NULL,                         NULL,                          DATEADD(DAY,-5,SYSDATETIME())),
(N'Pham Thi Hanh',   N'hanh.pt@gmail.com', N'0988001005',N'teacher',N'Biology teacher applying for advertised position.',             N'REJECTED',@uAdmin,N'Position already filled.',  DATEADD(DAY,-3,SYSDATETIME()), DATEADD(DAY,-7,SYSDATETIME()));

-- ── 20. FEEDBACK TICKETS ──────────────────────────────────────
INSERT INTO FeedbackTickets(SenderUserId,RelatedStudentId,Category,Subject,Content,Status,HandledBy,HandledAt,AdminResponse,CreatedAt) VALUES
(@uP01,@sId01,N'ACADEMIC',N'Math quiz retake policy',
    N'My son Pham Quoc Bao missed Math Quiz 1 due to fever. Is there a retake policy?',
    N'RESOLVED',@uAdmin,DATEADD(DAY,-12,SYSDATETIME()),
    N'Students with a medical certificate may sit a makeup assessment. Submit the certificate to your homeroom teacher within 3 days.',
    DATEADD(DAY,-14,SYSDATETIME())),
(@uP09,@sId09,N'GENERAL',N'Request for past exam papers',
    N'Could the school provide access to past Semester 1 exam papers for practice?',
    N'IN_PROGRESS',@uAdmin,NULL,NULL,
    DATEADD(DAY,-6,SYSDATETIME())),
(@uS10,NULL,N'GENERAL',N'Portal login issue',
    N'I cannot log in. Username khoa.vm keeps getting invalid password error.',
    N'OPEN',NULL,NULL,NULL,
    DATEADD(DAY,-2,SYSDATETIME()));

-- ── DONE ──────────────────────────────────────────────────────
PRINT N'';
PRINT N'=======================================================';
PRINT N'  eStudiez seed completed!';
PRINT N'';
PRINT N'  Users    : 1 admin + 10 teachers + 16 students + 16 parents';
PRINT N'  Subjects : 10  |  Classes: 4  |  Semesters: 2';
PRINT N'  Timetable: 100 slots  |  Assessments: 36  |  Marks: 144';
PRINT N'  Resources: 18  |  News: 8  |  Notifications: 8';
PRINT N'  Chat groups: 8  |  Reg. requests: 5  |  Feedback: 3';
PRINT N'';
PRINT N'  admin          / Admin@123';
PRINT N'  teacher.math   / Teacher@123   (all 10 teachers)';
PRINT N'  bao.pq         / Student@123   (all 16 students)';
PRINT N'  parent.bao     / Parent@123    (all 16 parents)';
PRINT N'=======================================================';
GO
