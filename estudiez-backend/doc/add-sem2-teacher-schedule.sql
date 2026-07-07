-- =============================================================
--  eStudiez — Lịch dạy HK2 đầy đủ cho giáo viên (cả 10, 11, 12)
--  Thêm Lesson Sessions cho 10A1 (sau 19/6), 10A2, 11A1 (đủ môn), 11A2
--  3 tuần: 06-Jul → 18-Jul 2026
--  Tuần 1 (06-11 Jul): COMPLETED + Attendance
--  Tuần 2 (13-18 Jul): SCHEDULED
--
--  Run: sqlcmd -S localhost,1433 -U sa -P "1" -d eStudentDB
--             -i doc\add-sem2-teacher-schedule.sql
-- =============================================================
USE eStudentDB;
GO

-- ── Lookup IDs ────────────────────────────────────────────────
DECLARE @sem2 INT = (SELECT TOP 1 SemesterId FROM Semesters WHERE Name = N'Semester 2');

DECLARE @c10A1 INT = (SELECT ClassId FROM Classes WHERE Name = N'10A1');
DECLARE @c10A2 INT = (SELECT ClassId FROM Classes WHERE Name = N'10A2');
DECLARE @c11A1 INT = (SELECT ClassId FROM Classes WHERE Name = N'11A1');
DECLARE @c11A2 INT = (SELECT ClassId FROM Classes WHERE Name = N'11A2');

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

-- Teachers
DECLARE @tId01 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subMath AND ClassId = @c10A1);
DECLARE @tId02 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subLit  AND ClassId = @c10A1);
DECLARE @tId03 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subEng  AND ClassId = @c10A1);
DECLARE @tId04 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subPhy  AND ClassId = @c10A1);
DECLARE @tId05 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subChem AND ClassId = @c10A1);
DECLARE @tId06 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subBio  AND ClassId = @c10A1);
DECLARE @tId07 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subHis  AND ClassId = @c10A1);
DECLARE @tId08 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subGeo  AND ClassId = @c10A1);
DECLARE @tId09 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subCs   AND ClassId = @c10A1);
DECLARE @tId10 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subPe   AND ClassId = @c10A1);

-- Teacher User IDs (for RecordedBy)
DECLARE @uT01 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId01);
DECLARE @uT02 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId02);
DECLARE @uT03 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId03);
DECLARE @uT04 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId04);
DECLARE @uT05 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId05);
DECLARE @uT06 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId06);
DECLARE @uT07 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId07);
DECLARE @uT08 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId08);
DECLARE @uT09 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId09);
DECLARE @uT10 UNIQUEIDENTIFIER = (SELECT u.UserId FROM Users u JOIN Teachers t ON t.UserId = u.UserId WHERE t.TeacherId = @tId10);

-- Student IDs — 10A1 (sId01-04), 10A2 (sId05-08), 11A1 (sId09-12), 11A2 (sId13-16)
DECLARE @sId01 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU001');
DECLARE @sId02 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU002');
DECLARE @sId03 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU003');
DECLARE @sId04 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU004');
DECLARE @sId05 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU005');
DECLARE @sId06 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU006');
DECLARE @sId07 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU007');
DECLARE @sId08 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU008');
DECLARE @sId09 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU009');
DECLARE @sId10 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU010');
DECLARE @sId11 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU011');
DECLARE @sId12 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU012');
DECLARE @sId13 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU013');
DECLARE @sId14 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU014');
DECLARE @sId15 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU015');
DECLARE @sId16 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU016');

-- ══════════════════════════════════════════════════════════════
-- TUẦN 1: 06-Jul (Mon) → 11-Jul (Sat) — COMPLETED
-- ══════════════════════════════════════════════════════════════

-- ─────────────────── 10A1 ────────────────────────────────────
-- 10A1 HK2: T2/4/6 Sáng: MATH(P1)-LIT(P2)-ENG(P3) Chiều: PHY(P6)-CHEM(P7)
--           T3/5   Sáng: BIO(P1)-HIS(P2)-GEO(P3)   Chiều: CS(P6)-PE(P7)
--           T7 Sáng ôn:  MATH(P1)-LIT(P2)-ENG(P3)

-- 10A1 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-07-06',1,N'101',N'Linear equations review',          N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-07-06',2,N'101',N'Reading comprehension skills',     N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-07-06',3,N'101',N'Present perfect tense',            N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-07-06',6,N'101',N'Waves and vibrations',             N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-07-06',7,N'101',N'Periodic table trends',            N'COMPLETED');
DECLARE @a10A1_0706 INT = SCOPE_IDENTITY() - 4;

-- 10A1 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-07-07',1,N'101',N'Plant cell structure',             N'COMPLETED'),
(@c10A1,@subHis, @tId07,'2026-07-07',2,N'101',N'Cold War overview',                N'COMPLETED'),
(@c10A1,@subGeo, @tId08,'2026-07-07',3,N'101',N'Weather systems',                  N'COMPLETED'),
(@c10A1,@subCs,  @tId09,'2026-07-07',6,N'101',N'Boolean logic and gates',          N'COMPLETED'),
(@c10A1,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Table tennis',                    N'COMPLETED');
DECLARE @a10A1_0707 INT = SCOPE_IDENTITY() - 4;

-- 10A1 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-07-08',1,N'101',N'Quadratic functions graphing',     N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-07-08',2,N'101',N'Narrative techniques',             N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-07-08',3,N'101',N'Past perfect tense',               N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-07-08',6,N'101',N'Sound waves',                     N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-07-08',7,N'101',N'Ionic bonding',                   N'COMPLETED');
DECLARE @a10A1_0708 INT = SCOPE_IDENTITY() - 4;

-- 10A1 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subBio, @tId06,'2026-07-09',1,N'101',N'Photosynthesis reactions',         N'COMPLETED'),
(@c10A1,@subHis, @tId07,'2026-07-09',2,N'101',N'Decolonization in Asia',           N'COMPLETED'),
(@c10A1,@subGeo, @tId08,'2026-07-09',3,N'101',N'Ocean currents',                   N'COMPLETED'),
(@c10A1,@subCs,  @tId09,'2026-07-09',6,N'101',N'Binary number system',             N'COMPLETED'),
(@c10A1,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Relay race training',              N'COMPLETED');
DECLARE @a10A1_0709 INT = SCOPE_IDENTITY() - 4;

-- 10A1 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-07-10',1,N'101',N'Polynomial long division',         N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-07-10',2,N'101',N'Character analysis essay',         N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-07-10',3,N'101',N'Conditionals review',              N'COMPLETED'),
(@c10A1,@subPhy, @tId04,'2026-07-10',6,N'101',N'Light refraction',                 N'COMPLETED'),
(@c10A1,@subChem,@tId05,'2026-07-10',7,N'101',N'Covalent bonding',                 N'COMPLETED');
DECLARE @a10A1_0710 INT = SCOPE_IDENTITY() - 4;

-- 10A1 T7 11-Jul (ôn tập)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-07-11',1,N'101',N'Review: Algebra unit',             N'COMPLETED'),
(@c10A1,@subLit, @tId02,'2026-07-11',2,N'101',N'Review: Essay writing',            N'COMPLETED'),
(@c10A1,@subEng, @tId03,'2026-07-11',3,N'101',N'Review: Grammar unit 2',           N'COMPLETED');
DECLARE @a10A1_0711 INT = SCOPE_IDENTITY() - 2;

-- ─────────────────── 10A2 ────────────────────────────────────
-- 10A2 HK2: T2/4/6 Sáng: PHY(P1)-MATH(P2)-ENG(P3) Chiều: LIT(P6)-CS(P7)
--           T3/5   Sáng: CHEM(P1)-BIO(P2)-HIS(P3)  Chiều: GEO(P6)-PE(P7)
--           T7 Sáng ôn:  PHY(P1)-MATH(P2)-ENG(P3)

-- 10A2 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subPhy, @tId04,'2026-07-06',1,N'102',N'Circular motion',                  N'COMPLETED'),
(@c10A2,@subMath,@tId01,'2026-07-06',2,N'102',N'Trigonometric identities',         N'COMPLETED'),
(@c10A2,@subEng, @tId03,'2026-07-06',3,N'102',N'Modal verbs review',               N'COMPLETED'),
(@c10A2,@subLit, @tId02,'2026-07-06',6,N'102',N'Classical Vietnamese poetry',      N'COMPLETED'),
(@c10A2,@subCs,  @tId09,'2026-07-06',7,N'102',N'Spreadsheet formulas',             N'COMPLETED');
DECLARE @a10A2_0706 INT = SCOPE_IDENTITY() - 4;

-- 10A2 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subChem,@tId05,'2026-07-07',1,N'102',N'Chemical equations balancing',     N'COMPLETED'),
(@c10A2,@subBio, @tId06,'2026-07-07',2,N'102',N'Animal cell vs plant cell',        N'COMPLETED'),
(@c10A2,@subHis, @tId07,'2026-07-07',3,N'102',N'French colonialism in VN',         N'COMPLETED'),
(@c10A2,@subGeo, @tId08,'2026-07-07',6,N'102',N'River systems',                    N'COMPLETED'),
(@c10A2,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Badminton basics',                 N'COMPLETED');
DECLARE @a10A2_0707 INT = SCOPE_IDENTITY() - 4;

-- 10A2 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subPhy, @tId04,'2026-07-08',1,N'102',N'Gravitation and satellites',       N'COMPLETED'),
(@c10A2,@subMath,@tId01,'2026-07-08',2,N'102',N'Sine and cosine rules',            N'COMPLETED'),
(@c10A2,@subEng, @tId03,'2026-07-08',3,N'102',N'Passive voice',                    N'COMPLETED'),
(@c10A2,@subLit, @tId02,'2026-07-08',6,N'102',N'Prose: "Vo chong A Phu"',           N'COMPLETED'),
(@c10A2,@subCs,  @tId09,'2026-07-08',7,N'102',N'Data sorting algorithms',          N'COMPLETED');
DECLARE @a10A2_0708 INT = SCOPE_IDENTITY() - 4;

-- 10A2 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subChem,@tId05,'2026-07-09',1,N'102',N'Redox reactions',                  N'COMPLETED'),
(@c10A2,@subBio, @tId06,'2026-07-09',2,N'102',N'Cellular respiration',             N'COMPLETED'),
(@c10A2,@subHis, @tId07,'2026-07-09',3,N'102',N'1945 August Revolution',           N'COMPLETED'),
(@c10A2,@subGeo, @tId08,'2026-07-09',6,N'102',N'Soil and agriculture',             N'COMPLETED'),
(@c10A2,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Jumping and landing techniques',   N'COMPLETED');
DECLARE @a10A2_0709 INT = SCOPE_IDENTITY() - 4;

-- 10A2 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subPhy, @tId04,'2026-07-10',1,N'102',N'Momentum and impulse',             N'COMPLETED'),
(@c10A2,@subMath,@tId01,'2026-07-10',2,N'102',N'Vectors in 2D',                    N'COMPLETED'),
(@c10A2,@subEng, @tId03,'2026-07-10',3,N'102',N'Writing paragraphs',               N'COMPLETED'),
(@c10A2,@subLit, @tId02,'2026-07-10',6,N'102',N'Short story analysis',             N'COMPLETED'),
(@c10A2,@subCs,  @tId09,'2026-07-10',7,N'102',N'Introduction to Python',           N'COMPLETED');
DECLARE @a10A2_0710 INT = SCOPE_IDENTITY() - 4;

-- 10A2 T7 11-Jul (ôn tập)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subPhy, @tId04,'2026-07-11',1,N'102',N'Review: Mechanics',                N'COMPLETED'),
(@c10A2,@subMath,@tId01,'2026-07-11',2,N'102',N'Review: Trigonometry',             N'COMPLETED'),
(@c10A2,@subEng, @tId03,'2026-07-11',3,N'102',N'Review: Grammar unit 2',           N'COMPLETED');
DECLARE @a10A2_0711 INT = SCOPE_IDENTITY() - 2;

-- ─────────────────── 11A1 ────────────────────────────────────
-- 11A1 HK2: T2/4/6 Sáng: LIT(P1)-MATH(P2)-ENG(P3) Chiều: PHY(P6)-CS(P7)
--           T3/5   Sáng: CHEM(P1)-BIO(P2)-HIS(P3)  Chiều: GEO(P6)-PE(P7)
--           T7 Sáng ôn:  LIT(P1)-MATH(P2)-ENG(P3)

-- 11A1 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subLit, @tId02,'2026-07-06',1,N'201',N'Narrative poetry analysis',        N'COMPLETED'),
(@c11A1,@subMath,@tId01,'2026-07-06',2,N'201',N'Exponential functions',            N'COMPLETED'),
(@c11A1,@subEng, @tId03,'2026-07-06',3,N'201',N'Relative clauses',                 N'COMPLETED'),
(@c11A1,@subPhy, @tId04,'2026-07-06',6,N'201',N'Thermodynamics basics',            N'COMPLETED'),
(@c11A1,@subCs,  @tId09,'2026-07-06',7,N'201',N'Object-oriented concepts',         N'COMPLETED');
DECLARE @a11A1_0706 INT = SCOPE_IDENTITY() - 4;

-- 11A1 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subChem,@tId05,'2026-07-07',1,N'201',N'Nitrogen compounds',               N'COMPLETED'),
(@c11A1,@subBio, @tId06,'2026-07-07',2,N'201',N'Nervous system',                   N'COMPLETED'),
(@c11A1,@subHis, @tId07,'2026-07-07',3,N'201',N'Vietnamese independence movement', N'COMPLETED'),
(@c11A1,@subGeo, @tId08,'2026-07-07',6,N'201',N'Mineral resources',                N'COMPLETED'),
(@c11A1,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Yoga and stretching',              N'COMPLETED');
DECLARE @a11A1_0707 INT = SCOPE_IDENTITY() - 4;

-- 11A1 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subLit, @tId02,'2026-07-08',1,N'201',N'Modern prose techniques',          N'COMPLETED'),
(@c11A1,@subMath,@tId01,'2026-07-08',2,N'201',N'Logarithmic equations',            N'COMPLETED'),
(@c11A1,@subEng, @tId03,'2026-07-08',3,N'201',N'Reported speech',                  N'COMPLETED'),
(@c11A1,@subPhy, @tId04,'2026-07-08',6,N'201',N'Heat transfer methods',            N'COMPLETED'),
(@c11A1,@subCs,  @tId09,'2026-07-08',7,N'201',N'Recursion and problem solving',    N'COMPLETED');
DECLARE @a11A1_0708 INT = SCOPE_IDENTITY() - 4;

-- 11A1 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subChem,@tId05,'2026-07-09',1,N'201',N'Phosphorus chemistry',             N'COMPLETED'),
(@c11A1,@subBio, @tId06,'2026-07-09',2,N'201',N'Endocrine system',                 N'COMPLETED'),
(@c11A1,@subHis, @tId07,'2026-07-09',3,N'201',N'Indochina war 1946-1954',          N'COMPLETED'),
(@c11A1,@subGeo, @tId08,'2026-07-09',6,N'201',N'Energy resources in VN',           N'COMPLETED'),
(@c11A1,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Swimming techniques',              N'COMPLETED');
DECLARE @a11A1_0709 INT = SCOPE_IDENTITY() - 4;

-- 11A1 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subLit, @tId02,'2026-07-10',1,N'201',N'Drama analysis: "Vu Nhu To"',       N'COMPLETED'),
(@c11A1,@subMath,@tId01,'2026-07-10',2,N'201',N'Sequences and series',             N'COMPLETED'),
(@c11A1,@subEng, @tId03,'2026-07-10',3,N'201',N'Essay structure review',           N'COMPLETED'),
(@c11A1,@subPhy, @tId04,'2026-07-10',6,N'201',N'Carnot cycle',                     N'COMPLETED'),
(@c11A1,@subCs,  @tId09,'2026-07-10',7,N'201',N'Searching algorithms',             N'COMPLETED');
DECLARE @a11A1_0710 INT = SCOPE_IDENTITY() - 4;

-- 11A1 T7 11-Jul (ôn tập)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subLit, @tId02,'2026-07-11',1,N'201',N'Review: Literary devices',         N'COMPLETED'),
(@c11A1,@subMath,@tId01,'2026-07-11',2,N'201',N'Review: Functions and logs',       N'COMPLETED'),
(@c11A1,@subEng, @tId03,'2026-07-11',3,N'201',N'Review: Reported speech',          N'COMPLETED');
DECLARE @a11A1_0711 INT = SCOPE_IDENTITY() - 2;

-- ─────────────────── 11A2 ────────────────────────────────────
-- 11A2 HK2: T2/4/6 Sáng: ENG(P1)-LIT(P2)-MATH(P3) Chiều: PHY(P6)-BIO(P7)
--           T3/5   Sáng: CHEM(P1)-HIS(P2)-GEO(P3)  Chiều: CS(P6)-PE(P7)
--           T7 Sáng ôn:  ENG(P1)-LIT(P2)-MATH(P3)

-- 11A2 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subEng, @tId03,'2026-07-06',1,N'202',N'Advanced vocabulary strategies',   N'COMPLETED'),
(@c11A2,@subLit, @tId02,'2026-07-06',2,N'202',N'Poetry: "Day thon Vi Da"',          N'COMPLETED'),
(@c11A2,@subMath,@tId01,'2026-07-06',3,N'202',N'Complex numbers intro',            N'COMPLETED'),
(@c11A2,@subPhy, @tId04,'2026-07-06',6,N'202',N'Electric potential energy',        N'COMPLETED'),
(@c11A2,@subBio, @tId06,'2026-07-06',7,N'202',N'Immune system',                    N'COMPLETED');
DECLARE @a11A2_0706 INT = SCOPE_IDENTITY() - 4;

-- 11A2 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subChem,@tId05,'2026-07-07',1,N'202',N'Sulfuric acid properties',         N'COMPLETED'),
(@c11A2,@subHis, @tId07,'2026-07-07',2,N'202',N'Ho Chi Minh and nationalism',      N'COMPLETED'),
(@c11A2,@subGeo, @tId08,'2026-07-07',3,N'202',N'Monsoon climate zones',            N'COMPLETED'),
(@c11A2,@subCs,  @tId09,'2026-07-07',6,N'202',N'Arrays and lists',                 N'COMPLETED'),
(@c11A2,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Football drills',                  N'COMPLETED');
DECLARE @a11A2_0707 INT = SCOPE_IDENTITY() - 4;

-- 11A2 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subEng, @tId03,'2026-07-08',1,N'202',N'Listening: academic lectures',     N'COMPLETED'),
(@c11A2,@subLit, @tId02,'2026-07-08',2,N'202',N'Short story: "Doi moi"',           N'COMPLETED'),
(@c11A2,@subMath,@tId01,'2026-07-08',3,N'202',N'Complex number operations',        N'COMPLETED'),
(@c11A2,@subPhy, @tId04,'2026-07-08',6,N'202',N'Electric field lines',             N'COMPLETED'),
(@c11A2,@subBio, @tId06,'2026-07-08',7,N'202',N'Reproductive systems',             N'COMPLETED');
DECLARE @a11A2_0708 INT = SCOPE_IDENTITY() - 4;

-- 11A2 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subChem,@tId05,'2026-07-09',1,N'202',N'Metal activity series',            N'COMPLETED'),
(@c11A2,@subHis, @tId07,'2026-07-09',2,N'202',N'Geneva Accords 1954',              N'COMPLETED'),
(@c11A2,@subGeo, @tId08,'2026-07-09',3,N'202',N'Forest and environment',           N'COMPLETED'),
(@c11A2,@subCs,  @tId09,'2026-07-09',6,N'202',N'Linked lists concept',             N'COMPLETED'),
(@c11A2,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Athletics: long jump',             N'COMPLETED');
DECLARE @a11A2_0709 INT = SCOPE_IDENTITY() - 4;

-- 11A2 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subEng, @tId03,'2026-07-10',1,N'202',N'Debate skills practice',           N'COMPLETED'),
(@c11A2,@subLit, @tId02,'2026-07-10',2,N'202',N'Argumentative prose',              N'COMPLETED'),
(@c11A2,@subMath,@tId01,'2026-07-10',3,N'202',N'Binomial theorem',                 N'COMPLETED'),
(@c11A2,@subPhy, @tId04,'2026-07-10',6,N'202',N'Coulombs law applications',        N'COMPLETED'),
(@c11A2,@subBio, @tId06,'2026-07-10',7,N'202',N'Plant reproduction',               N'COMPLETED');
DECLARE @a11A2_0710 INT = SCOPE_IDENTITY() - 4;

-- 11A2 T7 11-Jul (ôn tập)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subEng, @tId03,'2026-07-11',1,N'202',N'Review: Listening skills',         N'COMPLETED'),
(@c11A2,@subLit, @tId02,'2026-07-11',2,N'202',N'Review: Poetry techniques',        N'COMPLETED'),
(@c11A2,@subMath,@tId01,'2026-07-11',3,N'202',N'Review: Complex numbers',          N'COMPLETED');
DECLARE @a11A2_0711 INT = SCOPE_IDENTITY() - 2;

-- ══════════════════════════════════════════════════════════════
-- ĐIỂM DANH TUẦN 1 (06-11 Jul) — tất cả 4 lớp 10+11
-- ══════════════════════════════════════════════════════════════

-- 10A1 T2 06-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0706,  @sId01,N'PRESENT',@uT01),(@a10A1_0706,  @sId02,N'PRESENT',@uT01),(@a10A1_0706,  @sId03,N'LATE',  @uT01),(@a10A1_0706,  @sId04,N'PRESENT',@uT01),
(@a10A1_0706+1,@sId01,N'PRESENT',@uT02),(@a10A1_0706+1,@sId02,N'PRESENT',@uT02),(@a10A1_0706+1,@sId03,N'PRESENT',@uT02),(@a10A1_0706+1,@sId04,N'PRESENT',@uT02),
(@a10A1_0706+2,@sId01,N'PRESENT',@uT03),(@a10A1_0706+2,@sId02,N'ABSENT', @uT03),(@a10A1_0706+2,@sId03,N'PRESENT',@uT03),(@a10A1_0706+2,@sId04,N'PRESENT',@uT03),
(@a10A1_0706+3,@sId01,N'PRESENT',@uT04),(@a10A1_0706+3,@sId02,N'PRESENT',@uT04),(@a10A1_0706+3,@sId03,N'PRESENT',@uT04),(@a10A1_0706+3,@sId04,N'PRESENT',@uT04),
(@a10A1_0706+4,@sId01,N'PRESENT',@uT05),(@a10A1_0706+4,@sId02,N'PRESENT',@uT05),(@a10A1_0706+4,@sId03,N'PRESENT',@uT05),(@a10A1_0706+4,@sId04,N'PRESENT',@uT05);
-- 10A1 T3 07-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0707,  @sId01,N'PRESENT',@uT06),(@a10A1_0707,  @sId02,N'PRESENT',@uT06),(@a10A1_0707,  @sId03,N'PRESENT',@uT06),(@a10A1_0707,  @sId04,N'PRESENT',@uT06),
(@a10A1_0707+1,@sId01,N'LATE',  @uT07),(@a10A1_0707+1,@sId02,N'PRESENT',@uT07),(@a10A1_0707+1,@sId03,N'PRESENT',@uT07),(@a10A1_0707+1,@sId04,N'PRESENT',@uT07),
(@a10A1_0707+2,@sId01,N'PRESENT',@uT08),(@a10A1_0707+2,@sId02,N'PRESENT',@uT08),(@a10A1_0707+2,@sId03,N'PRESENT',@uT08),(@a10A1_0707+2,@sId04,N'ABSENT', @uT08),
(@a10A1_0707+3,@sId01,N'PRESENT',@uT09),(@a10A1_0707+3,@sId02,N'PRESENT',@uT09),(@a10A1_0707+3,@sId03,N'PRESENT',@uT09),(@a10A1_0707+3,@sId04,N'PRESENT',@uT09),
(@a10A1_0707+4,@sId01,N'PRESENT',@uT10),(@a10A1_0707+4,@sId02,N'PRESENT',@uT10),(@a10A1_0707+4,@sId03,N'PRESENT',@uT10),(@a10A1_0707+4,@sId04,N'PRESENT',@uT10);
-- 10A1 T4 08-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0708,  @sId01,N'PRESENT',@uT01),(@a10A1_0708,  @sId02,N'PRESENT',@uT01),(@a10A1_0708,  @sId03,N'PRESENT',@uT01),(@a10A1_0708,  @sId04,N'PRESENT',@uT01),
(@a10A1_0708+1,@sId01,N'PRESENT',@uT02),(@a10A1_0708+1,@sId02,N'LATE',  @uT02),(@a10A1_0708+1,@sId03,N'PRESENT',@uT02),(@a10A1_0708+1,@sId04,N'PRESENT',@uT02),
(@a10A1_0708+2,@sId01,N'PRESENT',@uT03),(@a10A1_0708+2,@sId02,N'PRESENT',@uT03),(@a10A1_0708+2,@sId03,N'PRESENT',@uT03),(@a10A1_0708+2,@sId04,N'PRESENT',@uT03),
(@a10A1_0708+3,@sId01,N'PRESENT',@uT04),(@a10A1_0708+3,@sId02,N'PRESENT',@uT04),(@a10A1_0708+3,@sId03,N'ABSENT', @uT04),(@a10A1_0708+3,@sId04,N'PRESENT',@uT04),
(@a10A1_0708+4,@sId01,N'PRESENT',@uT05),(@a10A1_0708+4,@sId02,N'PRESENT',@uT05),(@a10A1_0708+4,@sId03,N'PRESENT',@uT05),(@a10A1_0708+4,@sId04,N'PRESENT',@uT05);
-- 10A1 T5 09-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0709,  @sId01,N'PRESENT',@uT06),(@a10A1_0709,  @sId02,N'PRESENT',@uT06),(@a10A1_0709,  @sId03,N'PRESENT',@uT06),(@a10A1_0709,  @sId04,N'PRESENT',@uT06),
(@a10A1_0709+1,@sId01,N'PRESENT',@uT07),(@a10A1_0709+1,@sId02,N'PRESENT',@uT07),(@a10A1_0709+1,@sId03,N'PRESENT',@uT07),(@a10A1_0709+1,@sId04,N'PRESENT',@uT07),
(@a10A1_0709+2,@sId01,N'PRESENT',@uT08),(@a10A1_0709+2,@sId02,N'LATE',  @uT08),(@a10A1_0709+2,@sId03,N'PRESENT',@uT08),(@a10A1_0709+2,@sId04,N'PRESENT',@uT08),
(@a10A1_0709+3,@sId01,N'PRESENT',@uT09),(@a10A1_0709+3,@sId02,N'PRESENT',@uT09),(@a10A1_0709+3,@sId03,N'ABSENT', @uT09),(@a10A1_0709+3,@sId04,N'PRESENT',@uT09),
(@a10A1_0709+4,@sId01,N'PRESENT',@uT10),(@a10A1_0709+4,@sId02,N'PRESENT',@uT10),(@a10A1_0709+4,@sId03,N'PRESENT',@uT10),(@a10A1_0709+4,@sId04,N'PRESENT',@uT10);
-- 10A1 T6 10-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0710,  @sId01,N'PRESENT',@uT01),(@a10A1_0710,  @sId02,N'PRESENT',@uT01),(@a10A1_0710,  @sId03,N'PRESENT',@uT01),(@a10A1_0710,  @sId04,N'PRESENT',@uT01),
(@a10A1_0710+1,@sId01,N'PRESENT',@uT02),(@a10A1_0710+1,@sId02,N'PRESENT',@uT02),(@a10A1_0710+1,@sId03,N'PRESENT',@uT02),(@a10A1_0710+1,@sId04,N'ABSENT', @uT02),
(@a10A1_0710+2,@sId01,N'PRESENT',@uT03),(@a10A1_0710+2,@sId02,N'PRESENT',@uT03),(@a10A1_0710+2,@sId03,N'PRESENT',@uT03),(@a10A1_0710+2,@sId04,N'PRESENT',@uT03),
(@a10A1_0710+3,@sId01,N'PRESENT',@uT04),(@a10A1_0710+3,@sId02,N'LATE',  @uT04),(@a10A1_0710+3,@sId03,N'PRESENT',@uT04),(@a10A1_0710+3,@sId04,N'PRESENT',@uT04),
(@a10A1_0710+4,@sId01,N'PRESENT',@uT05),(@a10A1_0710+4,@sId02,N'PRESENT',@uT05),(@a10A1_0710+4,@sId03,N'PRESENT',@uT05),(@a10A1_0710+4,@sId04,N'PRESENT',@uT05);
-- 10A1 T7 11-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A1_0711,  @sId01,N'PRESENT',@uT01),(@a10A1_0711,  @sId02,N'PRESENT',@uT01),(@a10A1_0711,  @sId03,N'PRESENT',@uT01),(@a10A1_0711,  @sId04,N'PRESENT',@uT01),
(@a10A1_0711+1,@sId01,N'PRESENT',@uT02),(@a10A1_0711+1,@sId02,N'PRESENT',@uT02),(@a10A1_0711+1,@sId03,N'LATE',  @uT02),(@a10A1_0711+1,@sId04,N'PRESENT',@uT02),
(@a10A1_0711+2,@sId01,N'PRESENT',@uT03),(@a10A1_0711+2,@sId02,N'PRESENT',@uT03),(@a10A1_0711+2,@sId03,N'PRESENT',@uT03),(@a10A1_0711+2,@sId04,N'PRESENT',@uT03);

-- 10A2 T2 06-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A2_0706,  @sId05,N'PRESENT',@uT04),(@a10A2_0706,  @sId06,N'PRESENT',@uT04),(@a10A2_0706,  @sId07,N'PRESENT',@uT04),(@a10A2_0706,  @sId08,N'LATE',  @uT04),
(@a10A2_0706+1,@sId05,N'PRESENT',@uT01),(@a10A2_0706+1,@sId06,N'ABSENT', @uT01),(@a10A2_0706+1,@sId07,N'PRESENT',@uT01),(@a10A2_0706+1,@sId08,N'PRESENT',@uT01),
(@a10A2_0706+2,@sId05,N'PRESENT',@uT03),(@a10A2_0706+2,@sId06,N'PRESENT',@uT03),(@a10A2_0706+2,@sId07,N'PRESENT',@uT03),(@a10A2_0706+2,@sId08,N'PRESENT',@uT03),
(@a10A2_0706+3,@sId05,N'PRESENT',@uT02),(@a10A2_0706+3,@sId06,N'PRESENT',@uT02),(@a10A2_0706+3,@sId07,N'LATE',  @uT02),(@a10A2_0706+3,@sId08,N'PRESENT',@uT02),
(@a10A2_0706+4,@sId05,N'PRESENT',@uT09),(@a10A2_0706+4,@sId06,N'PRESENT',@uT09),(@a10A2_0706+4,@sId07,N'PRESENT',@uT09),(@a10A2_0706+4,@sId08,N'PRESENT',@uT09);
-- 10A2 T3 07-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A2_0707,  @sId05,N'PRESENT',@uT05),(@a10A2_0707,  @sId06,N'PRESENT',@uT05),(@a10A2_0707,  @sId07,N'PRESENT',@uT05),(@a10A2_0707,  @sId08,N'PRESENT',@uT05),
(@a10A2_0707+1,@sId05,N'PRESENT',@uT06),(@a10A2_0707+1,@sId06,N'PRESENT',@uT06),(@a10A2_0707+1,@sId07,N'ABSENT', @uT06),(@a10A2_0707+1,@sId08,N'PRESENT',@uT06),
(@a10A2_0707+2,@sId05,N'LATE',  @uT07),(@a10A2_0707+2,@sId06,N'PRESENT',@uT07),(@a10A2_0707+2,@sId07,N'PRESENT',@uT07),(@a10A2_0707+2,@sId08,N'PRESENT',@uT07),
(@a10A2_0707+3,@sId05,N'PRESENT',@uT08),(@a10A2_0707+3,@sId06,N'PRESENT',@uT08),(@a10A2_0707+3,@sId07,N'PRESENT',@uT08),(@a10A2_0707+3,@sId08,N'PRESENT',@uT08),
(@a10A2_0707+4,@sId05,N'PRESENT',@uT10),(@a10A2_0707+4,@sId06,N'PRESENT',@uT10),(@a10A2_0707+4,@sId07,N'PRESENT',@uT10),(@a10A2_0707+4,@sId08,N'PRESENT',@uT10);
-- 10A2 T4-T7 condensed
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a10A2_0708,  @sId05,N'PRESENT',@uT04),(@a10A2_0708,  @sId06,N'PRESENT',@uT04),(@a10A2_0708,  @sId07,N'LATE',  @uT04),(@a10A2_0708,  @sId08,N'PRESENT',@uT04),
(@a10A2_0708+1,@sId05,N'PRESENT',@uT01),(@a10A2_0708+1,@sId06,N'PRESENT',@uT01),(@a10A2_0708+1,@sId07,N'PRESENT',@uT01),(@a10A2_0708+1,@sId08,N'PRESENT',@uT01),
(@a10A2_0708+2,@sId05,N'PRESENT',@uT03),(@a10A2_0708+2,@sId06,N'ABSENT', @uT03),(@a10A2_0708+2,@sId07,N'PRESENT',@uT03),(@a10A2_0708+2,@sId08,N'PRESENT',@uT03),
(@a10A2_0708+3,@sId05,N'PRESENT',@uT02),(@a10A2_0708+3,@sId06,N'PRESENT',@uT02),(@a10A2_0708+3,@sId07,N'PRESENT',@uT02),(@a10A2_0708+3,@sId08,N'PRESENT',@uT02),
(@a10A2_0708+4,@sId05,N'PRESENT',@uT09),(@a10A2_0708+4,@sId06,N'PRESENT',@uT09),(@a10A2_0708+4,@sId07,N'PRESENT',@uT09),(@a10A2_0708+4,@sId08,N'PRESENT',@uT09),
(@a10A2_0709,  @sId05,N'PRESENT',@uT05),(@a10A2_0709,  @sId06,N'PRESENT',@uT05),(@a10A2_0709,  @sId07,N'PRESENT',@uT05),(@a10A2_0709,  @sId08,N'PRESENT',@uT05),
(@a10A2_0709+1,@sId05,N'PRESENT',@uT06),(@a10A2_0709+1,@sId06,N'LATE',  @uT06),(@a10A2_0709+1,@sId07,N'PRESENT',@uT06),(@a10A2_0709+1,@sId08,N'PRESENT',@uT06),
(@a10A2_0709+2,@sId05,N'PRESENT',@uT07),(@a10A2_0709+2,@sId06,N'PRESENT',@uT07),(@a10A2_0709+2,@sId07,N'ABSENT', @uT07),(@a10A2_0709+2,@sId08,N'PRESENT',@uT07),
(@a10A2_0709+3,@sId05,N'PRESENT',@uT08),(@a10A2_0709+3,@sId06,N'PRESENT',@uT08),(@a10A2_0709+3,@sId07,N'PRESENT',@uT08),(@a10A2_0709+3,@sId08,N'PRESENT',@uT08),
(@a10A2_0709+4,@sId05,N'PRESENT',@uT10),(@a10A2_0709+4,@sId06,N'PRESENT',@uT10),(@a10A2_0709+4,@sId07,N'PRESENT',@uT10),(@a10A2_0709+4,@sId08,N'PRESENT',@uT10),
(@a10A2_0710,  @sId05,N'PRESENT',@uT04),(@a10A2_0710,  @sId06,N'PRESENT',@uT04),(@a10A2_0710,  @sId07,N'PRESENT',@uT04),(@a10A2_0710,  @sId08,N'PRESENT',@uT04),
(@a10A2_0710+1,@sId05,N'LATE',  @uT01),(@a10A2_0710+1,@sId06,N'PRESENT',@uT01),(@a10A2_0710+1,@sId07,N'PRESENT',@uT01),(@a10A2_0710+1,@sId08,N'PRESENT',@uT01),
(@a10A2_0710+2,@sId05,N'PRESENT',@uT03),(@a10A2_0710+2,@sId06,N'PRESENT',@uT03),(@a10A2_0710+2,@sId07,N'PRESENT',@uT03),(@a10A2_0710+2,@sId08,N'ABSENT', @uT03),
(@a10A2_0710+3,@sId05,N'PRESENT',@uT02),(@a10A2_0710+3,@sId06,N'PRESENT',@uT02),(@a10A2_0710+3,@sId07,N'PRESENT',@uT02),(@a10A2_0710+3,@sId08,N'PRESENT',@uT02),
(@a10A2_0710+4,@sId05,N'PRESENT',@uT09),(@a10A2_0710+4,@sId06,N'PRESENT',@uT09),(@a10A2_0710+4,@sId07,N'PRESENT',@uT09),(@a10A2_0710+4,@sId08,N'PRESENT',@uT09),
(@a10A2_0711,  @sId05,N'PRESENT',@uT04),(@a10A2_0711,  @sId06,N'PRESENT',@uT04),(@a10A2_0711,  @sId07,N'PRESENT',@uT04),(@a10A2_0711,  @sId08,N'PRESENT',@uT04),
(@a10A2_0711+1,@sId05,N'PRESENT',@uT01),(@a10A2_0711+1,@sId06,N'LATE',  @uT01),(@a10A2_0711+1,@sId07,N'PRESENT',@uT01),(@a10A2_0711+1,@sId08,N'PRESENT',@uT01),
(@a10A2_0711+2,@sId05,N'PRESENT',@uT03),(@a10A2_0711+2,@sId06,N'PRESENT',@uT03),(@a10A2_0711+2,@sId07,N'PRESENT',@uT03),(@a10A2_0711+2,@sId08,N'PRESENT',@uT03);

-- 11A1 Attendance tuần 1 (condensed)
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a11A1_0706,  @sId09,N'PRESENT',@uT02),(@a11A1_0706,  @sId10,N'PRESENT',@uT02),(@a11A1_0706,  @sId11,N'LATE',  @uT02),(@a11A1_0706,  @sId12,N'PRESENT',@uT02),
(@a11A1_0706+1,@sId09,N'PRESENT',@uT01),(@a11A1_0706+1,@sId10,N'ABSENT', @uT01),(@a11A1_0706+1,@sId11,N'PRESENT',@uT01),(@a11A1_0706+1,@sId12,N'PRESENT',@uT01),
(@a11A1_0706+2,@sId09,N'PRESENT',@uT03),(@a11A1_0706+2,@sId10,N'PRESENT',@uT03),(@a11A1_0706+2,@sId11,N'PRESENT',@uT03),(@a11A1_0706+2,@sId12,N'PRESENT',@uT03),
(@a11A1_0706+3,@sId09,N'PRESENT',@uT04),(@a11A1_0706+3,@sId10,N'PRESENT',@uT04),(@a11A1_0706+3,@sId11,N'PRESENT',@uT04),(@a11A1_0706+3,@sId12,N'PRESENT',@uT04),
(@a11A1_0706+4,@sId09,N'PRESENT',@uT09),(@a11A1_0706+4,@sId10,N'PRESENT',@uT09),(@a11A1_0706+4,@sId11,N'PRESENT',@uT09),(@a11A1_0706+4,@sId12,N'PRESENT',@uT09),
(@a11A1_0707,  @sId09,N'PRESENT',@uT05),(@a11A1_0707,  @sId10,N'PRESENT',@uT05),(@a11A1_0707,  @sId11,N'PRESENT',@uT05),(@a11A1_0707,  @sId12,N'PRESENT',@uT05),
(@a11A1_0707+1,@sId09,N'PRESENT',@uT06),(@a11A1_0707+1,@sId10,N'LATE',  @uT06),(@a11A1_0707+1,@sId11,N'PRESENT',@uT06),(@a11A1_0707+1,@sId12,N'PRESENT',@uT06),
(@a11A1_0707+2,@sId09,N'PRESENT',@uT07),(@a11A1_0707+2,@sId10,N'PRESENT',@uT07),(@a11A1_0707+2,@sId11,N'ABSENT', @uT07),(@a11A1_0707+2,@sId12,N'PRESENT',@uT07),
(@a11A1_0707+3,@sId09,N'PRESENT',@uT08),(@a11A1_0707+3,@sId10,N'PRESENT',@uT08),(@a11A1_0707+3,@sId11,N'PRESENT',@uT08),(@a11A1_0707+3,@sId12,N'PRESENT',@uT08),
(@a11A1_0707+4,@sId09,N'PRESENT',@uT10),(@a11A1_0707+4,@sId10,N'PRESENT',@uT10),(@a11A1_0707+4,@sId11,N'PRESENT',@uT10),(@a11A1_0707+4,@sId12,N'PRESENT',@uT10),
(@a11A1_0708,  @sId09,N'PRESENT',@uT02),(@a11A1_0708,  @sId10,N'PRESENT',@uT02),(@a11A1_0708,  @sId11,N'PRESENT',@uT02),(@a11A1_0708,  @sId12,N'PRESENT',@uT02),
(@a11A1_0708+1,@sId09,N'PRESENT',@uT01),(@a11A1_0708+1,@sId10,N'PRESENT',@uT01),(@a11A1_0708+1,@sId11,N'LATE',  @uT01),(@a11A1_0708+1,@sId12,N'PRESENT',@uT01),
(@a11A1_0708+2,@sId09,N'PRESENT',@uT03),(@a11A1_0708+2,@sId10,N'PRESENT',@uT03),(@a11A1_0708+2,@sId11,N'PRESENT',@uT03),(@a11A1_0708+2,@sId12,N'ABSENT', @uT03),
(@a11A1_0708+3,@sId09,N'PRESENT',@uT04),(@a11A1_0708+3,@sId10,N'PRESENT',@uT04),(@a11A1_0708+3,@sId11,N'PRESENT',@uT04),(@a11A1_0708+3,@sId12,N'PRESENT',@uT04),
(@a11A1_0708+4,@sId09,N'PRESENT',@uT09),(@a11A1_0708+4,@sId10,N'PRESENT',@uT09),(@a11A1_0708+4,@sId11,N'PRESENT',@uT09),(@a11A1_0708+4,@sId12,N'PRESENT',@uT09),
(@a11A1_0709,  @sId09,N'PRESENT',@uT05),(@a11A1_0709,  @sId10,N'PRESENT',@uT05),(@a11A1_0709,  @sId11,N'PRESENT',@uT05),(@a11A1_0709,  @sId12,N'PRESENT',@uT05),
(@a11A1_0709+1,@sId09,N'PRESENT',@uT06),(@a11A1_0709+1,@sId10,N'PRESENT',@uT06),(@a11A1_0709+1,@sId11,N'PRESENT',@uT06),(@a11A1_0709+1,@sId12,N'LATE',  @uT06),
(@a11A1_0709+2,@sId09,N'ABSENT', @uT07),(@a11A1_0709+2,@sId10,N'PRESENT',@uT07),(@a11A1_0709+2,@sId11,N'PRESENT',@uT07),(@a11A1_0709+2,@sId12,N'PRESENT',@uT07),
(@a11A1_0709+3,@sId09,N'PRESENT',@uT08),(@a11A1_0709+3,@sId10,N'PRESENT',@uT08),(@a11A1_0709+3,@sId11,N'PRESENT',@uT08),(@a11A1_0709+3,@sId12,N'PRESENT',@uT08),
(@a11A1_0709+4,@sId09,N'PRESENT',@uT10),(@a11A1_0709+4,@sId10,N'PRESENT',@uT10),(@a11A1_0709+4,@sId11,N'PRESENT',@uT10),(@a11A1_0709+4,@sId12,N'PRESENT',@uT10),
(@a11A1_0710,  @sId09,N'PRESENT',@uT02),(@a11A1_0710,  @sId10,N'LATE',  @uT02),(@a11A1_0710,  @sId11,N'PRESENT',@uT02),(@a11A1_0710,  @sId12,N'PRESENT',@uT02),
(@a11A1_0710+1,@sId09,N'PRESENT',@uT01),(@a11A1_0710+1,@sId10,N'PRESENT',@uT01),(@a11A1_0710+1,@sId11,N'PRESENT',@uT01),(@a11A1_0710+1,@sId12,N'PRESENT',@uT01),
(@a11A1_0710+2,@sId09,N'PRESENT',@uT03),(@a11A1_0710+2,@sId10,N'PRESENT',@uT03),(@a11A1_0710+2,@sId11,N'ABSENT', @uT03),(@a11A1_0710+2,@sId12,N'PRESENT',@uT03),
(@a11A1_0710+3,@sId09,N'PRESENT',@uT04),(@a11A1_0710+3,@sId10,N'PRESENT',@uT04),(@a11A1_0710+3,@sId11,N'PRESENT',@uT04),(@a11A1_0710+3,@sId12,N'PRESENT',@uT04),
(@a11A1_0710+4,@sId09,N'PRESENT',@uT09),(@a11A1_0710+4,@sId10,N'PRESENT',@uT09),(@a11A1_0710+4,@sId11,N'PRESENT',@uT09),(@a11A1_0710+4,@sId12,N'PRESENT',@uT09),
(@a11A1_0711,  @sId09,N'PRESENT',@uT02),(@a11A1_0711,  @sId10,N'PRESENT',@uT02),(@a11A1_0711,  @sId11,N'PRESENT',@uT02),(@a11A1_0711,  @sId12,N'PRESENT',@uT02),
(@a11A1_0711+1,@sId09,N'PRESENT',@uT01),(@a11A1_0711+1,@sId10,N'PRESENT',@uT01),(@a11A1_0711+1,@sId11,N'PRESENT',@uT01),(@a11A1_0711+1,@sId12,N'LATE',  @uT01),
(@a11A1_0711+2,@sId09,N'PRESENT',@uT03),(@a11A1_0711+2,@sId10,N'PRESENT',@uT03),(@a11A1_0711+2,@sId11,N'PRESENT',@uT03),(@a11A1_0711+2,@sId12,N'PRESENT',@uT03);

-- 11A2 Attendance tuần 1 (condensed)
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@a11A2_0706,  @sId13,N'PRESENT',@uT03),(@a11A2_0706,  @sId14,N'PRESENT',@uT03),(@a11A2_0706,  @sId15,N'PRESENT',@uT03),(@a11A2_0706,  @sId16,N'LATE',  @uT03),
(@a11A2_0706+1,@sId13,N'PRESENT',@uT02),(@a11A2_0706+1,@sId14,N'ABSENT', @uT02),(@a11A2_0706+1,@sId15,N'PRESENT',@uT02),(@a11A2_0706+1,@sId16,N'PRESENT',@uT02),
(@a11A2_0706+2,@sId13,N'PRESENT',@uT01),(@a11A2_0706+2,@sId14,N'PRESENT',@uT01),(@a11A2_0706+2,@sId15,N'PRESENT',@uT01),(@a11A2_0706+2,@sId16,N'PRESENT',@uT01),
(@a11A2_0706+3,@sId13,N'PRESENT',@uT04),(@a11A2_0706+3,@sId14,N'PRESENT',@uT04),(@a11A2_0706+3,@sId15,N'LATE',  @uT04),(@a11A2_0706+3,@sId16,N'PRESENT',@uT04),
(@a11A2_0706+4,@sId13,N'PRESENT',@uT06),(@a11A2_0706+4,@sId14,N'PRESENT',@uT06),(@a11A2_0706+4,@sId15,N'PRESENT',@uT06),(@a11A2_0706+4,@sId16,N'PRESENT',@uT06),
(@a11A2_0707,  @sId13,N'PRESENT',@uT05),(@a11A2_0707,  @sId14,N'PRESENT',@uT05),(@a11A2_0707,  @sId15,N'PRESENT',@uT05),(@a11A2_0707,  @sId16,N'PRESENT',@uT05),
(@a11A2_0707+1,@sId13,N'PRESENT',@uT07),(@a11A2_0707+1,@sId14,N'PRESENT',@uT07),(@a11A2_0707+1,@sId15,N'ABSENT', @uT07),(@a11A2_0707+1,@sId16,N'PRESENT',@uT07),
(@a11A2_0707+2,@sId13,N'LATE',  @uT08),(@a11A2_0707+2,@sId14,N'PRESENT',@uT08),(@a11A2_0707+2,@sId15,N'PRESENT',@uT08),(@a11A2_0707+2,@sId16,N'PRESENT',@uT08),
(@a11A2_0707+3,@sId13,N'PRESENT',@uT09),(@a11A2_0707+3,@sId14,N'PRESENT',@uT09),(@a11A2_0707+3,@sId15,N'PRESENT',@uT09),(@a11A2_0707+3,@sId16,N'PRESENT',@uT09),
(@a11A2_0707+4,@sId13,N'PRESENT',@uT10),(@a11A2_0707+4,@sId14,N'PRESENT',@uT10),(@a11A2_0707+4,@sId15,N'PRESENT',@uT10),(@a11A2_0707+4,@sId16,N'PRESENT',@uT10),
(@a11A2_0708,  @sId13,N'PRESENT',@uT03),(@a11A2_0708,  @sId14,N'PRESENT',@uT03),(@a11A2_0708,  @sId15,N'PRESENT',@uT03),(@a11A2_0708,  @sId16,N'PRESENT',@uT03),
(@a11A2_0708+1,@sId13,N'ABSENT', @uT02),(@a11A2_0708+1,@sId14,N'PRESENT',@uT02),(@a11A2_0708+1,@sId15,N'PRESENT',@uT02),(@a11A2_0708+1,@sId16,N'PRESENT',@uT02),
(@a11A2_0708+2,@sId13,N'PRESENT',@uT01),(@a11A2_0708+2,@sId14,N'LATE',  @uT01),(@a11A2_0708+2,@sId15,N'PRESENT',@uT01),(@a11A2_0708+2,@sId16,N'PRESENT',@uT01),
(@a11A2_0708+3,@sId13,N'PRESENT',@uT04),(@a11A2_0708+3,@sId14,N'PRESENT',@uT04),(@a11A2_0708+3,@sId15,N'PRESENT',@uT04),(@a11A2_0708+3,@sId16,N'PRESENT',@uT04),
(@a11A2_0708+4,@sId13,N'PRESENT',@uT06),(@a11A2_0708+4,@sId14,N'PRESENT',@uT06),(@a11A2_0708+4,@sId15,N'LATE',  @uT06),(@a11A2_0708+4,@sId16,N'PRESENT',@uT06),
(@a11A2_0709,  @sId13,N'PRESENT',@uT05),(@a11A2_0709,  @sId14,N'PRESENT',@uT05),(@a11A2_0709,  @sId15,N'PRESENT',@uT05),(@a11A2_0709,  @sId16,N'PRESENT',@uT05),
(@a11A2_0709+1,@sId13,N'PRESENT',@uT07),(@a11A2_0709+1,@sId14,N'PRESENT',@uT07),(@a11A2_0709+1,@sId15,N'PRESENT',@uT07),(@a11A2_0709+1,@sId16,N'ABSENT', @uT07),
(@a11A2_0709+2,@sId13,N'PRESENT',@uT08),(@a11A2_0709+2,@sId14,N'PRESENT',@uT08),(@a11A2_0709+2,@sId15,N'PRESENT',@uT08),(@a11A2_0709+2,@sId16,N'PRESENT',@uT08),
(@a11A2_0709+3,@sId13,N'PRESENT',@uT09),(@a11A2_0709+3,@sId14,N'LATE',  @uT09),(@a11A2_0709+3,@sId15,N'PRESENT',@uT09),(@a11A2_0709+3,@sId16,N'PRESENT',@uT09),
(@a11A2_0709+4,@sId13,N'PRESENT',@uT10),(@a11A2_0709+4,@sId14,N'PRESENT',@uT10),(@a11A2_0709+4,@sId15,N'PRESENT',@uT10),(@a11A2_0709+4,@sId16,N'PRESENT',@uT10),
(@a11A2_0710,  @sId13,N'PRESENT',@uT03),(@a11A2_0710,  @sId14,N'PRESENT',@uT03),(@a11A2_0710,  @sId15,N'LATE',  @uT03),(@a11A2_0710,  @sId16,N'PRESENT',@uT03),
(@a11A2_0710+1,@sId13,N'PRESENT',@uT02),(@a11A2_0710+1,@sId14,N'PRESENT',@uT02),(@a11A2_0710+1,@sId15,N'PRESENT',@uT02),(@a11A2_0710+1,@sId16,N'PRESENT',@uT02),
(@a11A2_0710+2,@sId13,N'PRESENT',@uT01),(@a11A2_0710+2,@sId14,N'ABSENT', @uT01),(@a11A2_0710+2,@sId15,N'PRESENT',@uT01),(@a11A2_0710+2,@sId16,N'PRESENT',@uT01),
(@a11A2_0710+3,@sId13,N'PRESENT',@uT04),(@a11A2_0710+3,@sId14,N'PRESENT',@uT04),(@a11A2_0710+3,@sId15,N'PRESENT',@uT04),(@a11A2_0710+3,@sId16,N'PRESENT',@uT04),
(@a11A2_0710+4,@sId13,N'PRESENT',@uT06),(@a11A2_0710+4,@sId14,N'PRESENT',@uT06),(@a11A2_0710+4,@sId15,N'PRESENT',@uT06),(@a11A2_0710+4,@sId16,N'PRESENT',@uT06),
(@a11A2_0711,  @sId13,N'PRESENT',@uT03),(@a11A2_0711,  @sId14,N'PRESENT',@uT03),(@a11A2_0711,  @sId15,N'PRESENT',@uT03),(@a11A2_0711,  @sId16,N'PRESENT',@uT03),
(@a11A2_0711+1,@sId13,N'PRESENT',@uT02),(@a11A2_0711+1,@sId14,N'LATE',  @uT02),(@a11A2_0711+1,@sId15,N'PRESENT',@uT02),(@a11A2_0711+1,@sId16,N'PRESENT',@uT02),
(@a11A2_0711+2,@sId13,N'PRESENT',@uT01),(@a11A2_0711+2,@sId14,N'PRESENT',@uT01),(@a11A2_0711+2,@sId15,N'PRESENT',@uT01),(@a11A2_0711+2,@sId16,N'PRESENT',@uT01);

-- ══════════════════════════════════════════════════════════════
-- TUẦN 2: 13-Jul (Mon) → 18-Jul (Sat) — SCHEDULED
-- ══════════════════════════════════════════════════════════════

-- 10A1 Tuần 2
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A1,@subMath,@tId01,'2026-07-13',1,N'101',N'Rational functions',               N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-07-13',2,N'101',N'Imagery in Vietnamese poetry',     N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-07-13',3,N'101',N'Future tenses',                    N'SCHEDULED'),
(@c10A1,@subPhy, @tId04,'2026-07-13',6,N'101',N'Light spectrum',                   N'SCHEDULED'),
(@c10A1,@subChem,@tId05,'2026-07-13',7,N'101',N'Metallic bonding',                 N'SCHEDULED'),
(@c10A1,@subBio, @tId06,'2026-07-14',1,N'101',N'Cell division: mitosis',           N'SCHEDULED'),
(@c10A1,@subHis, @tId07,'2026-07-14',2,N'101',N'Post-WW2 world order',             N'SCHEDULED'),
(@c10A1,@subGeo, @tId08,'2026-07-14',3,N'101',N'Natural disasters',                N'SCHEDULED'),
(@c10A1,@subCs,  @tId09,'2026-07-14',6,N'101',N'Computer networks intro',          N'SCHEDULED'),
(@c10A1,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Basketball tournament',            N'SCHEDULED'),
(@c10A1,@subMath,@tId01,'2026-07-15',1,N'101',N'Radical expressions',              N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-07-15',2,N'101',N'Persuasive writing techniques',    N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-07-15',3,N'101',N'Question tags',                    N'SCHEDULED'),
(@c10A1,@subPhy, @tId04,'2026-07-15',6,N'101',N'Electromagnetic spectrum',         N'SCHEDULED'),
(@c10A1,@subChem,@tId05,'2026-07-15',7,N'101',N'Acid-base reactions',              N'SCHEDULED'),
(@c10A1,@subBio, @tId06,'2026-07-16',1,N'101',N'Meiosis and reproduction',         N'SCHEDULED'),
(@c10A1,@subHis, @tId07,'2026-07-16',2,N'101',N'European integration',             N'SCHEDULED'),
(@c10A1,@subGeo, @tId08,'2026-07-16',3,N'101',N'Climate change impact',            N'SCHEDULED'),
(@c10A1,@subCs,  @tId09,'2026-07-16',6,N'101',N'Internet and web basics',          N'SCHEDULED'),
(@c10A1,@subPe,  @tId10,'2026-07-16',7,N'GYM',N'Volleyball final match',           N'SCHEDULED'),
(@c10A1,@subMath,@tId01,'2026-07-17',1,N'101',N'Absolute value equations',         N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-07-17',2,N'101',N'Book report presentation',         N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-07-17',3,N'101',N'Mid-unit review',                  N'SCHEDULED'),
(@c10A1,@subPhy, @tId04,'2026-07-17',6,N'101',N'Optics: mirrors',                  N'SCHEDULED'),
(@c10A1,@subChem,@tId05,'2026-07-17',7,N'101',N'Buffer solutions',                 N'SCHEDULED'),
(@c10A1,@subMath,@tId01,'2026-07-18',1,N'101',N'Review: Week 2 problems',          N'SCHEDULED'),
(@c10A1,@subLit, @tId02,'2026-07-18',2,N'101',N'Review: Writing skills',           N'SCHEDULED'),
(@c10A1,@subEng, @tId03,'2026-07-18',3,N'101',N'Review: Tenses revision',          N'SCHEDULED');

-- 10A2 Tuần 2
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c10A2,@subPhy, @tId04,'2026-07-13',1,N'102',N'Conservation of energy',           N'SCHEDULED'),
(@c10A2,@subMath,@tId01,'2026-07-13',2,N'102',N'Statistics: mean and variance',    N'SCHEDULED'),
(@c10A2,@subEng, @tId03,'2026-07-13',3,N'102',N'Discourse markers',                N'SCHEDULED'),
(@c10A2,@subLit, @tId02,'2026-07-13',6,N'102',N'Drama: "Bac si Stockman"',          N'SCHEDULED'),
(@c10A2,@subCs,  @tId09,'2026-07-13',7,N'102',N'File handling in Python',          N'SCHEDULED'),
(@c10A2,@subChem,@tId05,'2026-07-14',1,N'102',N'Electrochemistry basics',          N'SCHEDULED'),
(@c10A2,@subBio, @tId06,'2026-07-14',2,N'102',N'Osmosis and diffusion',            N'SCHEDULED'),
(@c10A2,@subHis, @tId07,'2026-07-14',3,N'102',N'UN and global peacekeeping',       N'SCHEDULED'),
(@c10A2,@subGeo, @tId08,'2026-07-14',6,N'102',N'Global warming effects',           N'SCHEDULED'),
(@c10A2,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Swimming competition',             N'SCHEDULED'),
(@c10A2,@subPhy, @tId04,'2026-07-15',1,N'102',N'Work and power',                   N'SCHEDULED'),
(@c10A2,@subMath,@tId01,'2026-07-15',2,N'102',N'Probability distributions',        N'SCHEDULED'),
(@c10A2,@subEng, @tId03,'2026-07-15',3,N'102',N'Reading: Science articles',        N'SCHEDULED'),
(@c10A2,@subLit, @tId02,'2026-07-15',6,N'102',N'Symbolism in literature',          N'SCHEDULED'),
(@c10A2,@subCs,  @tId09,'2026-07-15',7,N'102',N'Recursion exercises',              N'SCHEDULED'),
(@c10A2,@subChem,@tId05,'2026-07-16',1,N'102',N'Galvanic cells',                   N'SCHEDULED'),
(@c10A2,@subBio, @tId06,'2026-07-16',2,N'102',N'Active transport',                 N'SCHEDULED'),
(@c10A2,@subHis, @tId07,'2026-07-16',3,N'102',N'Vietnam and ASEAN',                N'SCHEDULED'),
(@c10A2,@subGeo, @tId08,'2026-07-16',6,N'102',N'Sustainable development',          N'SCHEDULED'),
(@c10A2,@subPe,  @tId10,'2026-07-16',7,N'GYM',N'Cross-country run',                N'SCHEDULED'),
(@c10A2,@subPhy, @tId04,'2026-07-17',1,N'102',N'Simple harmonic motion',           N'SCHEDULED'),
(@c10A2,@subMath,@tId01,'2026-07-17',2,N'102',N'Combinatorics',                    N'SCHEDULED'),
(@c10A2,@subEng, @tId03,'2026-07-17',3,N'102',N'Writing: comparison essay',        N'SCHEDULED'),
(@c10A2,@subLit, @tId02,'2026-07-17',6,N'102',N'Postmodern literature intro',      N'SCHEDULED'),
(@c10A2,@subCs,  @tId09,'2026-07-17',7,N'102',N'OOP: classes and objects',         N'SCHEDULED'),
(@c10A2,@subPhy, @tId04,'2026-07-18',1,N'102',N'Review: Energy and motion',        N'SCHEDULED'),
(@c10A2,@subMath,@tId01,'2026-07-18',2,N'102',N'Review: Statistics',               N'SCHEDULED'),
(@c10A2,@subEng, @tId03,'2026-07-18',3,N'102',N'Review: Writing skills',           N'SCHEDULED');

-- 11A1 Tuần 2
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A1,@subLit, @tId02,'2026-07-13',1,N'201',N'Prose: "Chiec thuyen ngoai xa"',   N'SCHEDULED'),
(@c11A1,@subMath,@tId01,'2026-07-13',2,N'201',N'Geometric sequences',              N'SCHEDULED'),
(@c11A1,@subEng, @tId03,'2026-07-13',3,N'201',N'Participle clauses',               N'SCHEDULED'),
(@c11A1,@subPhy, @tId04,'2026-07-13',6,N'201',N'Entropy and disorder',             N'SCHEDULED'),
(@c11A1,@subCs,  @tId09,'2026-07-13',7,N'201',N'Graph algorithms',                 N'SCHEDULED'),
(@c11A1,@subChem,@tId05,'2026-07-14',1,N'201',N'Electroplating',                   N'SCHEDULED'),
(@c11A1,@subBio, @tId06,'2026-07-14',2,N'201',N'Hormonal regulation',              N'SCHEDULED'),
(@c11A1,@subHis, @tId07,'2026-07-14',3,N'201',N'Economic reforms 1986',            N'SCHEDULED'),
(@c11A1,@subGeo, @tId08,'2026-07-14',6,N'201',N'Tourism in Vietnam',               N'SCHEDULED'),
(@c11A1,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Gymnastics intro',                 N'SCHEDULED'),
(@c11A1,@subLit, @tId02,'2026-07-15',1,N'201',N'Existentialism in literature',     N'SCHEDULED'),
(@c11A1,@subMath,@tId01,'2026-07-15',2,N'201',N'Arithmetic series sums',           N'SCHEDULED'),
(@c11A1,@subEng, @tId03,'2026-07-15',3,N'201',N'Inversion for emphasis',           N'SCHEDULED'),
(@c11A1,@subPhy, @tId04,'2026-07-15',6,N'201',N'Ideal gas law',                    N'SCHEDULED'),
(@c11A1,@subCs,  @tId09,'2026-07-15',7,N'201',N'Dynamic programming',              N'SCHEDULED'),
(@c11A1,@subChem,@tId05,'2026-07-16',1,N'201',N'Industrial chemistry: ammonia',    N'SCHEDULED'),
(@c11A1,@subBio, @tId06,'2026-07-16',2,N'201',N'Sensory systems',                  N'SCHEDULED'),
(@c11A1,@subHis, @tId07,'2026-07-16',3,N'201',N'Vietnam in ASEAN',                 N'SCHEDULED'),
(@c11A1,@subGeo, @tId08,'2026-07-16',6,N'201',N'Urban planning challenges',        N'SCHEDULED'),
(@c11A1,@subPe,  @tId10,'2026-07-16',7,N'GYM',N'Strength and conditioning',        N'SCHEDULED'),
(@c11A1,@subLit, @tId02,'2026-07-17',1,N'201',N'Review: Narrative analysis',       N'SCHEDULED'),
(@c11A1,@subMath,@tId01,'2026-07-17',2,N'201',N'Review: Series and limits',        N'SCHEDULED'),
(@c11A1,@subEng, @tId03,'2026-07-17',3,N'201',N'Review: Advanced grammar',         N'SCHEDULED'),
(@c11A1,@subPhy, @tId04,'2026-07-17',6,N'201',N'Gas laws applications',            N'SCHEDULED'),
(@c11A1,@subCs,  @tId09,'2026-07-17',7,N'201',N'Problem-solving contest prep',     N'SCHEDULED'),
(@c11A1,@subLit, @tId02,'2026-07-18',1,N'201',N'Review: Prose styles',             N'SCHEDULED'),
(@c11A1,@subMath,@tId01,'2026-07-18',2,N'201',N'Review: Sequences exam prep',      N'SCHEDULED'),
(@c11A1,@subEng, @tId03,'2026-07-18',3,N'201',N'Review: Reading skills',           N'SCHEDULED');

-- 11A2 Tuần 2
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c11A2,@subEng, @tId03,'2026-07-13',1,N'202',N'Collocations and idioms',          N'SCHEDULED'),
(@c11A2,@subLit, @tId02,'2026-07-13',2,N'202',N'Satire in literature',             N'SCHEDULED'),
(@c11A2,@subMath,@tId01,'2026-07-13',3,N'202',N'Argand diagram',                   N'SCHEDULED'),
(@c11A2,@subPhy, @tId04,'2026-07-13',6,N'202',N'Capacitors in circuits',           N'SCHEDULED'),
(@c11A2,@subBio, @tId06,'2026-07-13',7,N'202',N'Ecology: food chains',             N'SCHEDULED'),
(@c11A2,@subChem,@tId05,'2026-07-14',1,N'202',N'Halogens chemistry',               N'SCHEDULED'),
(@c11A2,@subHis, @tId07,'2026-07-14',2,N'202',N'Cambodia-Vietnam relations',       N'SCHEDULED'),
(@c11A2,@subGeo, @tId08,'2026-07-14',3,N'202',N'Economic zones in Vietnam',        N'SCHEDULED'),
(@c11A2,@subCs,  @tId09,'2026-07-14',6,N'202',N'Stack and queue ADTs',             N'SCHEDULED'),
(@c11A2,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Obstacle course training',         N'SCHEDULED'),
(@c11A2,@subEng, @tId03,'2026-07-15',1,N'202',N'Critical reading skills',          N'SCHEDULED'),
(@c11A2,@subLit, @tId02,'2026-07-15',2,N'202',N'Translation theory',               N'SCHEDULED'),
(@c11A2,@subMath,@tId01,'2026-07-15',3,N'202',N'Modulus and argument',             N'SCHEDULED'),
(@c11A2,@subPhy, @tId04,'2026-07-15',6,N'202',N'RC circuit time constants',        N'SCHEDULED'),
(@c11A2,@subBio, @tId06,'2026-07-15',7,N'202',N'Biomes of the world',              N'SCHEDULED'),
(@c11A2,@subChem,@tId05,'2026-07-16',1,N'202',N'Noble gases applications',         N'SCHEDULED'),
(@c11A2,@subHis, @tId07,'2026-07-16',2,N'202',N'Laos-Vietnam solidarity',          N'SCHEDULED'),
(@c11A2,@subGeo, @tId08,'2026-07-16',3,N'202',N'Sea and islands of Vietnam',       N'SCHEDULED'),
(@c11A2,@subCs,  @tId09,'2026-07-16',6,N'202',N'Binary trees traversal',           N'SCHEDULED'),
(@c11A2,@subPe,  @tId10,'2026-07-16',7,N'GYM',N'Tennis skills',                    N'SCHEDULED'),
(@c11A2,@subEng, @tId03,'2026-07-17',1,N'202',N'Review: Listening strategies',     N'SCHEDULED'),
(@c11A2,@subLit, @tId02,'2026-07-17',2,N'202',N'Review: Literary analysis',        N'SCHEDULED'),
(@c11A2,@subMath,@tId01,'2026-07-17',3,N'202',N'Review: Complex numbers',          N'SCHEDULED'),
(@c11A2,@subPhy, @tId04,'2026-07-17',6,N'202',N'Review: Electrostatics',           N'SCHEDULED'),
(@c11A2,@subBio, @tId06,'2026-07-17',7,N'202',N'Review: Ecology',                  N'SCHEDULED'),
(@c11A2,@subEng, @tId03,'2026-07-18',1,N'202',N'Review: Speaking fluency',         N'SCHEDULED'),
(@c11A2,@subLit, @tId02,'2026-07-18',2,N'202',N'Review: Essay structures',         N'SCHEDULED'),
(@c11A2,@subMath,@tId01,'2026-07-18',3,N'202',N'Review: Algebra and complex',      N'SCHEDULED');

PRINT N'';
PRINT N'=======================================================';
PRINT N'  Lich day HK2 cho giao vien da duoc cap nhat!';
PRINT N'';
PRINT N'  Lesson Sessions them moi:';
PRINT N'    10A1: 28 sessions (tuan 1 completed + tuan 2 scheduled)';
PRINT N'    10A2: 28 sessions (tuan 1 completed + tuan 2 scheduled)';
PRINT N'    11A1: 28 sessions (tuan 1 completed + tuan 2 scheduled)';
PRINT N'    11A2: 28 sessions (tuan 1 completed + tuan 2 scheduled)';
PRINT N'';
PRINT N'  Attendance records: tuan 1 day du cho 10A1/10A2/11A1/11A2';
PRINT N'=======================================================';
GO
