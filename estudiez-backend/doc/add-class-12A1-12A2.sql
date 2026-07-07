-- =============================================================
--  eStudiez — Add Classes 12A1 and 12A2
--  Run against existing eStudentDB (does NOT reset/drop anything).
--
--  Run: sqlcmd -S localhost,1433 -U sa -P "YourStrong@Passw0rd" -d eStudentDB -i doc\add-class-12A1-12A2.sql
--
--  New Accounts created:
--    Students 12A1: son.nv / khanh.lt / trang.ht / phong.bd  / Student@123
--    Students 12A2: dung.tm / yen.nq  / tuan.vp  / nhi.lt    / Student@123
--    Parents:       parent.son ... parent.nhi                  / Parent@123
-- =============================================================
USE eStudentDB;
GO

-- ── Lookup existing references ─────────────────────────────────
DECLARE @rStudent INT = (SELECT RoleId FROM Roles WHERE Code = N'STUDENT');
DECLARE @rParent  INT = (SELECT RoleId FROM Roles WHERE Code = N'PARENT');

DECLARE @g12 INT = (SELECT GradeId FROM Grades WHERE Code = N'G12');
-- If Grade 12 does not exist yet, insert it
IF @g12 IS NULL
BEGIN
    INSERT INTO Grades (Code, Name) VALUES (N'G12', N'Grade 12');
    SET @g12 = SCOPE_IDENTITY();
END

DECLARE @syId INT    = (SELECT TOP 1 SchoolYearId FROM SchoolYears WHERE IsCurrent = 1);
DECLARE @sem1 INT    = (SELECT TOP 1 SemesterId   FROM Semesters WHERE SchoolYearId = @syId ORDER BY StartDate ASC);
DECLARE @sem2 INT    = (SELECT TOP 1 SemesterId   FROM Semesters WHERE SchoolYearId = @syId ORDER BY StartDate DESC);

-- Subjects
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

-- Existing teachers
DECLARE @tId01 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH001'); -- Math
DECLARE @tId02 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH002'); -- Lit
DECLARE @tId03 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH003'); -- Eng
DECLARE @tId04 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH004'); -- Phy
DECLARE @tId05 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH005'); -- Chem
DECLARE @tId06 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH006'); -- Bio
DECLARE @tId07 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH007'); -- His
DECLARE @tId08 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH008'); -- Geo
DECLARE @tId09 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH009'); -- CS
DECLARE @tId10 UNIQUEIDENTIFIER = (SELECT TeacherId FROM Teachers WHERE EmployeeCode = N'TCH010'); -- PE

-- Teacher user IDs (for RecordedBy in attendance)
DECLARE @uT05 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH005');
DECLARE @uT06 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH006');

-- Password hashes (same as existing seed)
DECLARE @HASH_STUDENT NVARCHAR(255) = (SELECT TOP 1 PasswordHash FROM Users WHERE Username = N'bao.pq');
DECLARE @HASH_PARENT  NVARCHAR(255) = (SELECT TOP 1 PasswordHash FROM Users WHERE Username = N'parent.bao');

-- ── Step 1: Generate User UUIDs ────────────────────────────────
DECLARE @uS17 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS18 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS19 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS20 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS21 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS22 UNIQUEIDENTIFIER = NEWID();
DECLARE @uS23 UNIQUEIDENTIFIER = NEWID(); DECLARE @uS24 UNIQUEIDENTIFIER = NEWID();

DECLARE @uP17 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP18 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP19 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP20 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP21 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP22 UNIQUEIDENTIFIER = NEWID();
DECLARE @uP23 UNIQUEIDENTIFIER = NEWID(); DECLARE @uP24 UNIQUEIDENTIFIER = NEWID();

-- ── Step 2: Insert Users ───────────────────────────────────────
-- Students 12A1
INSERT INTO Users (UserId,RoleId,Username,PasswordHash,FullName,Email,Phone,IsActive) VALUES
(@uS17,@rStudent,N'son.nv',   @HASH_STUDENT,N'Nguyen Van Son',   NULL,N'0912001017',1),
(@uS18,@rStudent,N'khanh.lt', @HASH_STUDENT,N'Le Thi Khanh',     NULL,N'0912001018',1),
(@uS19,@rStudent,N'trang.ht', @HASH_STUDENT,N'Ho Thi Trang',     NULL,N'0912001019',1),
(@uS20,@rStudent,N'phong.bd', @HASH_STUDENT,N'Bui Duc Phong',    NULL,N'0912001020',1);
-- Students 12A2
INSERT INTO Users (UserId,RoleId,Username,PasswordHash,FullName,Email,Phone,IsActive) VALUES
(@uS21,@rStudent,N'dung.tm',  @HASH_STUDENT,N'Tran Minh Dung',   NULL,N'0912001021',1),
(@uS22,@rStudent,N'yen.nq',   @HASH_STUDENT,N'Nguyen Quynh Yen', NULL,N'0912001022',1),
(@uS23,@rStudent,N'tuan.vp',  @HASH_STUDENT,N'Vo Phan Tuan',     NULL,N'0912001023',1),
(@uS24,@rStudent,N'nhi.lt',   @HASH_STUDENT,N'Le Thi Nhi',       NULL,N'0912001024',1);
-- Parents 12A1
INSERT INTO Users (UserId,RoleId,Username,PasswordHash,FullName,Email,Phone,IsActive) VALUES
(@uP17,@rParent,N'parent.son',   @HASH_PARENT,N'Nguyen Van Toan', N'toan.nv@gmail.com',  N'0903001017',1),
(@uP18,@rParent,N'parent.khanh', @HASH_PARENT,N'Le Van Chau',     N'chau.lv@gmail.com',  N'0903001018',1),
(@uP19,@rParent,N'parent.trang', @HASH_PARENT,N'Ho Van Phat',     N'phat.hv@gmail.com',  N'0903001019',1),
(@uP20,@rParent,N'parent.phong', @HASH_PARENT,N'Bui Thi Hue',     N'hue.bt@gmail.com',   N'0903001020',1);
-- Parents 12A2
INSERT INTO Users (UserId,RoleId,Username,PasswordHash,FullName,Email,Phone,IsActive) VALUES
(@uP21,@rParent,N'parent.dung',  @HASH_PARENT,N'Tran Van Lam',   N'lam.tv@gmail.com',   N'0903001021',1),
(@uP22,@rParent,N'parent.yen',   @HASH_PARENT,N'Nguyen Thi Bich',N'bich.nt@gmail.com',  N'0903001022',1),
(@uP23,@rParent,N'parent.tuan',  @HASH_PARENT,N'Vo Van Phuc',    N'phuc.vv@gmail.com',  N'0903001023',1),
(@uP24,@rParent,N'parent.nhi',   @HASH_PARENT,N'Le Van Cuong',   N'cuong.lv2@gmail.com',N'0903001024',1);

-- ── Step 3: Insert Students ────────────────────────────────────
DECLARE @sId17 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId18 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId19 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId20 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId21 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId22 UNIQUEIDENTIFIER = NEWID();
DECLARE @sId23 UNIQUEIDENTIFIER = NEWID(); DECLARE @sId24 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Students (StudentId,UserId,StudentCode,DateOfBirth,Gender,Address,AdmissionDate,Status) VALUES
(@sId17,@uS17,N'STU017','2006-02-14',N'Male',  N'10 Le Hong Phong, District 5, HCMC',   '2020-09-01',N'ACTIVE'),
(@sId18,@uS18,N'STU018','2006-05-23',N'Female',N'28 Tran Phu, District 5, HCMC',        '2020-09-01',N'ACTIVE'),
(@sId19,@uS19,N'STU019','2006-07-11',N'Female',N'44 Nguyen Thi Minh Khai, District 3',  '2020-09-01',N'ACTIVE'),
(@sId20,@uS20,N'STU020','2006-09-30',N'Male',  N'62 Ly Tu Trong, District 1, HCMC',     '2020-09-01',N'ACTIVE'),
(@sId21,@uS21,N'STU021','2006-01-07',N'Male',  N'88 Nguyen Van Troi, Phu Nhuan, HCMC',  '2020-09-01',N'ACTIVE'),
(@sId22,@uS22,N'STU022','2006-04-18',N'Female',N'15 Hoang Van Thu, Tan Binh, HCMC',     '2020-09-01',N'ACTIVE'),
(@sId23,@uS23,N'STU023','2006-08-25',N'Male',  N'33 Bach Dang, Binh Thanh, HCMC',       '2020-09-01',N'ACTIVE'),
(@sId24,@uS24,N'STU024','2006-11-03',N'Female',N'51 Pham Ngoc Thach, District 3, HCMC', '2020-09-01',N'ACTIVE');

-- ── Step 4: Insert Parents ─────────────────────────────────────
DECLARE @pId17 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId18 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId19 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId20 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId21 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId22 UNIQUEIDENTIFIER = NEWID();
DECLARE @pId23 UNIQUEIDENTIFIER = NEWID(); DECLARE @pId24 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Parents (ParentId,UserId,Occupation,Address) VALUES
(@pId17,@uP17,N'Manager',       N'10 Le Hong Phong, District 5, HCMC'),
(@pId18,@uP18,N'Doctor',        N'28 Tran Phu, District 5, HCMC'),
(@pId19,@uP19,N'Engineer',      N'44 Nguyen Thi Minh Khai, District 3'),
(@pId20,@uP20,N'Teacher',       N'62 Ly Tu Trong, District 1, HCMC'),
(@pId21,@uP21,N'Businessman',   N'88 Nguyen Van Troi, Phu Nhuan, HCMC'),
(@pId22,@uP22,N'Pharmacist',    N'15 Hoang Van Thu, Tan Binh, HCMC'),
(@pId23,@uP23,N'IT Specialist', N'33 Bach Dang, Binh Thanh, HCMC'),
(@pId24,@uP24,N'Accountant',    N'51 Pham Ngoc Thach, District 3, HCMC');

-- ── Step 5: Student–Parent links ──────────────────────────────
INSERT INTO StudentParentLinks (StudentId,ParentId,Relationship,IsPrimaryContact) VALUES
(@sId17,@pId17,N'Father',1),(@sId18,@pId18,N'Father',1),
(@sId19,@pId19,N'Father',1),(@sId20,@pId20,N'Mother',1),
(@sId21,@pId21,N'Father',1),(@sId22,@pId22,N'Mother',1),
(@sId23,@pId23,N'Father',1),(@sId24,@pId24,N'Father',1);

-- ── Step 6: Create Classes ─────────────────────────────────────
-- 12A1: homeroom = Chem teacher (tId05), room 301
INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g12,N'12A1',@tId05,N'REGULAR',N'301',1);
DECLARE @c12A1 INT = SCOPE_IDENTITY();

-- 12A2: homeroom = Bio teacher (tId06), room 302
INSERT INTO Classes (SchoolYearId,GradeId,Name,HomeroomTeacherId,TrainingProgram,Room,IsActive)
    VALUES (@syId,@g12,N'12A2',@tId06,N'REGULAR',N'302',1);
DECLARE @c12A2 INT = SCOPE_IDENTITY();

-- ── Step 7: Enroll students ────────────────────────────────────
INSERT INTO ClassEnrollments (ClassId,StudentId,EnrolledAt,Status) VALUES
(@c12A1,@sId17,'2025-09-01',N'ACTIVE'),(@c12A1,@sId18,'2025-09-01',N'ACTIVE'),
(@c12A1,@sId19,'2025-09-01',N'ACTIVE'),(@c12A1,@sId20,'2025-09-01',N'ACTIVE'),
(@c12A2,@sId21,'2025-09-01',N'ACTIVE'),(@c12A2,@sId22,'2025-09-01',N'ACTIVE'),
(@c12A2,@sId23,'2025-09-01',N'ACTIVE'),(@c12A2,@sId24,'2025-09-01',N'ACTIVE');

-- ── Step 8: Teacher–Class assignments ─────────────────────────
INSERT INTO TeacherClassAssignments (TeacherId,ClassId,SubjectId,SchoolYearId) VALUES
(@tId01,@c12A1,@subMath,@syId),(@tId02,@c12A1,@subLit, @syId),(@tId03,@c12A1,@subEng, @syId),
(@tId04,@c12A1,@subPhy, @syId),(@tId05,@c12A1,@subChem,@syId),(@tId06,@c12A1,@subBio, @syId),
(@tId07,@c12A1,@subHis, @syId),(@tId08,@c12A1,@subGeo, @syId),(@tId09,@c12A1,@subCs,  @syId),(@tId10,@c12A1,@subPe,@syId),
(@tId01,@c12A2,@subMath,@syId),(@tId02,@c12A2,@subLit, @syId),(@tId03,@c12A2,@subEng, @syId),
(@tId04,@c12A2,@subPhy, @syId),(@tId05,@c12A2,@subChem,@syId),(@tId06,@c12A2,@subBio, @syId),
(@tId07,@c12A2,@subHis, @syId),(@tId08,@c12A2,@subGeo, @syId),(@tId09,@c12A2,@subCs,  @syId),(@tId10,@c12A2,@subPe,@syId);

-- ── Step 9: Timetable slots (Mon-Fri x 5 periods x 2 classes) ─
-- 12A1: Mon/Wed/Fri: MATH LIT ENG PHY CHEM  |  Tue/Thu: BIO HIS GEO CS PE
-- 12A2: Mon/Wed/Fri: ENG MATH LIT CHEM BIO  |  Tue/Thu: PHY HIS GEO CS PE
DECLARE @eff DATE = '2025-09-05';
INSERT INTO TimetableSlots (ClassId,SubjectId,TeacherId,SemesterId,DayOfWeek,PeriodNo,StartTime,EndTime,Room,EffectiveFrom) VALUES
-- 12A1 Mon
(@c12A1,@subMath,@tId01,@sem1,1,1,'07:30','08:15',N'301',@eff),(@c12A1,@subLit, @tId02,@sem1,1,2,'08:25','09:10',N'301',@eff),
(@c12A1,@subEng, @tId03,@sem1,1,3,'09:20','10:05',N'301',@eff),(@c12A1,@subPhy, @tId04,@sem1,1,4,'10:15','11:00',N'301',@eff),
(@c12A1,@subChem,@tId05,@sem1,1,5,'11:10','11:55',N'301',@eff),
-- 12A1 Tue
(@c12A1,@subBio, @tId06,@sem1,2,1,'07:30','08:15',N'301',@eff),(@c12A1,@subHis, @tId07,@sem1,2,2,'08:25','09:10',N'301',@eff),
(@c12A1,@subGeo, @tId08,@sem1,2,3,'09:20','10:05',N'301',@eff),(@c12A1,@subCs,  @tId09,@sem1,2,4,'10:15','11:00',N'301',@eff),
(@c12A1,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'301',@eff),
-- 12A1 Wed
(@c12A1,@subMath,@tId01,@sem1,3,1,'07:30','08:15',N'301',@eff),(@c12A1,@subLit, @tId02,@sem1,3,2,'08:25','09:10',N'301',@eff),
(@c12A1,@subEng, @tId03,@sem1,3,3,'09:20','10:05',N'301',@eff),(@c12A1,@subPhy, @tId04,@sem1,3,4,'10:15','11:00',N'301',@eff),
(@c12A1,@subChem,@tId05,@sem1,3,5,'11:10','11:55',N'301',@eff),
-- 12A1 Thu
(@c12A1,@subBio, @tId06,@sem1,4,1,'07:30','08:15',N'301',@eff),(@c12A1,@subHis, @tId07,@sem1,4,2,'08:25','09:10',N'301',@eff),
(@c12A1,@subGeo, @tId08,@sem1,4,3,'09:20','10:05',N'301',@eff),(@c12A1,@subCs,  @tId09,@sem1,4,4,'10:15','11:00',N'301',@eff),
(@c12A1,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'301',@eff),
-- 12A1 Fri
(@c12A1,@subMath,@tId01,@sem1,5,1,'07:30','08:15',N'301',@eff),(@c12A1,@subLit, @tId02,@sem1,5,2,'08:25','09:10',N'301',@eff),
(@c12A1,@subEng, @tId03,@sem1,5,3,'09:20','10:05',N'301',@eff),(@c12A1,@subPhy, @tId04,@sem1,5,4,'10:15','11:00',N'301',@eff),
(@c12A1,@subChem,@tId05,@sem1,5,5,'11:10','11:55',N'301',@eff),
-- 12A2 Mon
(@c12A2,@subEng, @tId03,@sem1,1,1,'07:30','08:15',N'302',@eff),(@c12A2,@subMath,@tId01,@sem1,1,2,'08:25','09:10',N'302',@eff),
(@c12A2,@subLit, @tId02,@sem1,1,3,'09:20','10:05',N'302',@eff),(@c12A2,@subChem,@tId05,@sem1,1,4,'10:15','11:00',N'302',@eff),
(@c12A2,@subBio, @tId06,@sem1,1,5,'11:10','11:55',N'302',@eff),
-- 12A2 Tue
(@c12A2,@subPhy, @tId04,@sem1,2,1,'07:30','08:15',N'302',@eff),(@c12A2,@subHis, @tId07,@sem1,2,2,'08:25','09:10',N'302',@eff),
(@c12A2,@subGeo, @tId08,@sem1,2,3,'09:20','10:05',N'302',@eff),(@c12A2,@subCs,  @tId09,@sem1,2,4,'10:15','11:00',N'302',@eff),
(@c12A2,@subPe,  @tId10,@sem1,2,5,'11:10','11:55',N'302',@eff),
-- 12A2 Wed
(@c12A2,@subEng, @tId03,@sem1,3,1,'07:30','08:15',N'302',@eff),(@c12A2,@subMath,@tId01,@sem1,3,2,'08:25','09:10',N'302',@eff),
(@c12A2,@subLit, @tId02,@sem1,3,3,'09:20','10:05',N'302',@eff),(@c12A2,@subChem,@tId05,@sem1,3,4,'10:15','11:00',N'302',@eff),
(@c12A2,@subBio, @tId06,@sem1,3,5,'11:10','11:55',N'302',@eff),
-- 12A2 Thu
(@c12A2,@subPhy, @tId04,@sem1,4,1,'07:30','08:15',N'302',@eff),(@c12A2,@subHis, @tId07,@sem1,4,2,'08:25','09:10',N'302',@eff),
(@c12A2,@subGeo, @tId08,@sem1,4,3,'09:20','10:05',N'302',@eff),(@c12A2,@subCs,  @tId09,@sem1,4,4,'10:15','11:00',N'302',@eff),
(@c12A2,@subPe,  @tId10,@sem1,4,5,'11:10','11:55',N'302',@eff),
-- 12A2 Fri
(@c12A2,@subEng, @tId03,@sem1,5,1,'07:30','08:15',N'302',@eff),(@c12A2,@subMath,@tId01,@sem1,5,2,'08:25','09:10',N'302',@eff),
(@c12A2,@subLit, @tId02,@sem1,5,3,'09:20','10:05',N'302',@eff),(@c12A2,@subChem,@tId05,@sem1,5,4,'10:15','11:00',N'302',@eff),
(@c12A2,@subBio, @tId06,@sem1,5,5,'11:10','11:55',N'302',@eff);

-- ── Step 10: Sample Lesson Sessions (Week of Jul 7-11, 2026) ───
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
-- 12A1 Mon Jul 7
(@c12A1,@subMath,@tId01,'2026-07-07',1,N'301',N'Limits and Derivatives',N'COMPLETED'),
(@c12A1,@subLit, @tId02,'2026-07-07',2,N'301',N'Modern Vietnamese Poetry',N'COMPLETED'),
(@c12A1,@subEng, @tId03,'2026-07-07',3,N'301',N'IELTS Writing Task 2',N'COMPLETED'),
(@c12A1,@subPhy, @tId04,'2026-07-07',4,N'301',N'Electric fields',N'COMPLETED'),
(@c12A1,@subChem,@tId05,'2026-07-07',5,N'301',N'Organic Chemistry revision',N'COMPLETED');
DECLARE @ls12A1_Mon INT = SCOPE_IDENTITY() - 4;

INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
-- 12A1 Tue Jul 8
(@c12A1,@subBio, @tId06,'2026-07-08',1,N'301',N'Genetics and Heredity',N'COMPLETED'),
(@c12A1,@subHis, @tId07,'2026-07-08',2,N'301',N'Vietnam War overview',N'COMPLETED'),
(@c12A1,@subGeo, @tId08,'2026-07-08',3,N'301',N'Economic development regions',N'COMPLETED'),
(@c12A1,@subCs,  @tId09,'2026-07-08',4,N'301',N'Database design basics',N'COMPLETED'),
(@c12A1,@subPe,  @tId10,'2026-07-08',5,N'GYM',N'Volleyball',N'COMPLETED');
DECLARE @ls12A1_Tue INT = SCOPE_IDENTITY() - 4;

INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
-- 12A2 Mon Jul 7
(@c12A2,@subEng, @tId03,'2026-07-07',1,N'302',N'Advanced Grammar review',N'COMPLETED'),
(@c12A2,@subMath,@tId01,'2026-07-07',2,N'302',N'Integration techniques',N'COMPLETED'),
(@c12A2,@subLit, @tId02,'2026-07-07',3,N'302',N'Fiction analysis',N'COMPLETED'),
(@c12A2,@subChem,@tId05,'2026-07-07',4,N'302',N'Chemical equilibrium',N'COMPLETED'),
(@c12A2,@subBio, @tId06,'2026-07-07',5,N'302',N'Ecosystems and biodiversity',N'COMPLETED');
DECLARE @ls12A2_Mon INT = SCOPE_IDENTITY() - 4;

INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
-- 12A2 Tue Jul 8
(@c12A2,@subPhy, @tId04,'2026-07-08',1,N'302',N'Electromagnetic waves',N'COMPLETED'),
(@c12A2,@subHis, @tId07,'2026-07-08',2,N'302',N'Modern Asian history',N'COMPLETED'),
(@c12A2,@subGeo, @tId08,'2026-07-08',3,N'302',N'Urbanization trends',N'COMPLETED'),
(@c12A2,@subCs,  @tId09,'2026-07-08',4,N'302',N'Web development intro',N'COMPLETED'),
(@c12A2,@subPe,  @tId10,'2026-07-08',5,N'GYM',N'Badminton',N'COMPLETED');
DECLARE @ls12A2_Tue INT = SCOPE_IDENTITY() - 4;

-- ── Step 11: Attendance Records ────────────────────────────────
-- Get teacher UserIds for RecordedBy
DECLARE @uT01 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH001');
DECLARE @uT02 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH002');
DECLARE @uT03 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH003');
DECLARE @uT04 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH004');
DECLARE @uT07 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH007');
DECLARE @uT08 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH008');
DECLARE @uT09 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH009');
DECLARE @uT10 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.EmployeeCode = N'TCH010');

-- 12A1 Mon Jul 7 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_Mon,  @sId17,N'PRESENT',@uT01),(@ls12A1_Mon,  @sId18,N'PRESENT',@uT01),(@ls12A1_Mon,  @sId19,N'LATE',  @uT01),(@ls12A1_Mon,  @sId20,N'PRESENT',@uT01),
(@ls12A1_Mon+1,@sId17,N'PRESENT',@uT02),(@ls12A1_Mon+1,@sId18,N'PRESENT',@uT02),(@ls12A1_Mon+1,@sId19,N'PRESENT',@uT02),(@ls12A1_Mon+1,@sId20,N'PRESENT',@uT02),
(@ls12A1_Mon+2,@sId17,N'PRESENT',@uT03),(@ls12A1_Mon+2,@sId18,N'ABSENT', @uT03),(@ls12A1_Mon+2,@sId19,N'PRESENT',@uT03),(@ls12A1_Mon+2,@sId20,N'PRESENT',@uT03),
(@ls12A1_Mon+3,@sId17,N'PRESENT',@uT04),(@ls12A1_Mon+3,@sId18,N'PRESENT',@uT04),(@ls12A1_Mon+3,@sId19,N'PRESENT',@uT04),(@ls12A1_Mon+3,@sId20,N'LATE',  @uT04),
(@ls12A1_Mon+4,@sId17,N'PRESENT',@uT05),(@ls12A1_Mon+4,@sId18,N'PRESENT',@uT05),(@ls12A1_Mon+4,@sId19,N'PRESENT',@uT05),(@ls12A1_Mon+4,@sId20,N'PRESENT',@uT05);

-- 12A1 Tue Jul 8 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_Tue,  @sId17,N'PRESENT',@uT06),(@ls12A1_Tue,  @sId18,N'PRESENT',@uT06),(@ls12A1_Tue,  @sId19,N'PRESENT',@uT06),(@ls12A1_Tue,  @sId20,N'PRESENT',@uT06),
(@ls12A1_Tue+1,@sId17,N'LATE',  @uT07),(@ls12A1_Tue+1,@sId18,N'PRESENT',@uT07),(@ls12A1_Tue+1,@sId19,N'PRESENT',@uT07),(@ls12A1_Tue+1,@sId20,N'PRESENT',@uT07),
(@ls12A1_Tue+2,@sId17,N'PRESENT',@uT08),(@ls12A1_Tue+2,@sId18,N'PRESENT',@uT08),(@ls12A1_Tue+2,@sId19,N'PRESENT',@uT08),(@ls12A1_Tue+2,@sId20,N'PRESENT',@uT08),
(@ls12A1_Tue+3,@sId17,N'PRESENT',@uT09),(@ls12A1_Tue+3,@sId18,N'PRESENT',@uT09),(@ls12A1_Tue+3,@sId19,N'ABSENT', @uT09),(@ls12A1_Tue+3,@sId20,N'PRESENT',@uT09),
(@ls12A1_Tue+4,@sId17,N'PRESENT',@uT10),(@ls12A1_Tue+4,@sId18,N'PRESENT',@uT10),(@ls12A1_Tue+4,@sId19,N'PRESENT',@uT10),(@ls12A1_Tue+4,@sId20,N'PRESENT',@uT10);

-- 12A2 Mon Jul 7 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_Mon,  @sId21,N'PRESENT',@uT03),(@ls12A2_Mon,  @sId22,N'PRESENT',@uT03),(@ls12A2_Mon,  @sId23,N'PRESENT',@uT03),(@ls12A2_Mon,  @sId24,N'LATE',  @uT03),
(@ls12A2_Mon+1,@sId21,N'PRESENT',@uT01),(@ls12A2_Mon+1,@sId22,N'ABSENT', @uT01),(@ls12A2_Mon+1,@sId23,N'PRESENT',@uT01),(@ls12A2_Mon+1,@sId24,N'PRESENT',@uT01),
(@ls12A2_Mon+2,@sId21,N'PRESENT',@uT02),(@ls12A2_Mon+2,@sId22,N'PRESENT',@uT02),(@ls12A2_Mon+2,@sId23,N'LATE',  @uT02),(@ls12A2_Mon+2,@sId24,N'PRESENT',@uT02),
(@ls12A2_Mon+3,@sId21,N'PRESENT',@uT05),(@ls12A2_Mon+3,@sId22,N'PRESENT',@uT05),(@ls12A2_Mon+3,@sId23,N'PRESENT',@uT05),(@ls12A2_Mon+3,@sId24,N'PRESENT',@uT05),
(@ls12A2_Mon+4,@sId21,N'PRESENT',@uT06),(@ls12A2_Mon+4,@sId22,N'PRESENT',@uT06),(@ls12A2_Mon+4,@sId23,N'PRESENT',@uT06),(@ls12A2_Mon+4,@sId24,N'PRESENT',@uT06);

-- 12A2 Tue Jul 8 attendance
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_Tue,  @sId21,N'PRESENT',@uT04),(@ls12A2_Tue,  @sId22,N'PRESENT',@uT04),(@ls12A2_Tue,  @sId23,N'ABSENT', @uT04),(@ls12A2_Tue,  @sId24,N'PRESENT',@uT04),
(@ls12A2_Tue+1,@sId21,N'PRESENT',@uT07),(@ls12A2_Tue+1,@sId22,N'PRESENT',@uT07),(@ls12A2_Tue+1,@sId23,N'PRESENT',@uT07),(@ls12A2_Tue+1,@sId24,N'PRESENT',@uT07),
(@ls12A2_Tue+2,@sId21,N'PRESENT',@uT08),(@ls12A2_Tue+2,@sId22,N'LATE',  @uT08),(@ls12A2_Tue+2,@sId23,N'PRESENT',@uT08),(@ls12A2_Tue+2,@sId24,N'PRESENT',@uT08),
(@ls12A2_Tue+3,@sId21,N'PRESENT',@uT09),(@ls12A2_Tue+3,@sId22,N'PRESENT',@uT09),(@ls12A2_Tue+3,@sId23,N'PRESENT',@uT09),(@ls12A2_Tue+3,@sId24,N'PRESENT',@uT09),
(@ls12A2_Tue+4,@sId21,N'PRESENT',@uT10),(@ls12A2_Tue+4,@sId22,N'PRESENT',@uT10),(@ls12A2_Tue+4,@sId23,N'PRESENT',@uT10),(@ls12A2_Tue+4,@sId24,N'PRESENT',@uT10);

-- ── Step 12: Sample Assessments & Marks ───────────────────────
DECLARE @atQuiz  INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'QUIZ');
DECLARE @atMid   INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'MIDTERM');
DECLARE @atFinal INT = (SELECT AssessmentTypeId FROM AssessmentTypes WHERE Code = N'FINAL');

-- 12A1 - MATH
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A1,@subMath,@tId01,@sem2,@atQuiz,N'Math Quiz 1',   '2026-07-02',10,0.10,N'COMPLETED');
DECLARE @a12A1_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A1_MQ,@sId17,9.5,N'Excellent!',@tId01),(@a12A1_MQ,@sId18,8.0,N'Good.',@tId01),
(@a12A1_MQ,@sId19,7.5,N'Needs practice.',@tId01),(@a12A1_MQ,@sId20,9.0,N'Very good.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A1,@subMath,@tId01,@sem2,@atMid,N'Math Midterm',  '2026-07-04',10,0.30,N'COMPLETED');
DECLARE @a12A1_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A1_MM,@sId17,8.5,N'Very good.',@tId01),(@a12A1_MM,@sId18,7.0,N'Good effort.',@tId01),
(@a12A1_MM,@sId19,6.5,N'More revision needed.',@tId01),(@a12A1_MM,@sId20,8.0,N'Good.',@tId01);

-- 12A1 - ENGLISH
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A1,@subEng,@tId03,@sem2,@atQuiz,N'English Quiz 1','2026-07-03',10,0.10,N'COMPLETED');
DECLARE @a12A1_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A1_EQ,@sId17,9.0,N'Outstanding.',@tId03),(@a12A1_EQ,@sId18,8.5,N'Very good.',@tId03),
(@a12A1_EQ,@sId19,8.0,N'Good.',@tId03),(@a12A1_EQ,@sId20,7.5,N'Good.',@tId03);

-- 12A2 - MATH
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A2,@subMath,@tId01,@sem2,@atQuiz,N'Math Quiz 1',   '2026-07-02',10,0.10,N'COMPLETED');
DECLARE @a12A2_MQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A2_MQ,@sId21,8.0,N'Good.',@tId01),(@a12A2_MQ,@sId22,9.0,N'Excellent!',@tId01),
(@a12A2_MQ,@sId23,7.0,N'Average.',@tId01),(@a12A2_MQ,@sId24,8.5,N'Very good.',@tId01);

INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A2,@subMath,@tId01,@sem2,@atMid,N'Math Midterm',  '2026-07-04',10,0.30,N'COMPLETED');
DECLARE @a12A2_MM INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A2_MM,@sId21,7.5,N'Good effort.',@tId01),(@a12A2_MM,@sId22,8.5,N'Very good.',@tId01),
(@a12A2_MM,@sId23,6.0,N'More effort needed.',@tId01),(@a12A2_MM,@sId24,9.0,N'Excellent!',@tId01);

-- 12A2 - ENGLISH
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status)
VALUES(@c12A2,@subEng,@tId03,@sem2,@atQuiz,N'English Quiz 1','2026-07-03',10,0.10,N'COMPLETED');
DECLARE @a12A2_EQ INT = SCOPE_IDENTITY();
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,TeacherComment,GradedBy) VALUES
(@a12A2_EQ,@sId21,7.0,N'Good.',@tId03),(@a12A2_EQ,@sId22,9.5,N'Outstanding.',@tId03),
(@a12A2_EQ,@sId23,8.0,N'Very good.',@tId03),(@a12A2_EQ,@sId24,8.0,N'Good.',@tId03);

-- ── Done ──────────────────────────────────────────────────────
PRINT N'';
PRINT N'=======================================================';
PRINT N'  12A1 and 12A2 classes added successfully!';
PRINT N'';
PRINT N'  New students (password: Student@123):';
PRINT N'    12A1: son.nv / khanh.lt / trang.ht / phong.bd';
PRINT N'    12A2: dung.tm / yen.nq  / tuan.vp  / nhi.lt';
PRINT N'  New parents  (password: Parent@123):';
PRINT N'    parent.son / parent.khanh / parent.trang / parent.phong';
PRINT N'    parent.dung / parent.yen / parent.tuan / parent.nhi';
PRINT N'=======================================================';
GO
