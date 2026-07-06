-- =============================================================
--  eStudiez — Thêm lịch học kỳ 2 cho lớp 12A1 và 12A2
--  Học kỳ 2: 2026-06-01 → 2026-11-06
--
--  Cấu trúc tiết học kỳ 2 (giống các lớp 10/11):
--    Sáng:  P1=07:30-08:15  P2=08:25-09:10  P3=09:20-10:05
--    Chiều: P6=13:00-13:45  P7=13:50-14:35
--    Thứ 7: P1-P3 (phụ đạo ôn thi tốt nghiệp)
--
--  Lịch tuần:
--    12A1: T2/4/6 Sáng: Toán-Văn-Anh | Chiều: Lý-Hóa
--           T3/5   Sáng: Sinh-Sử-Địa  | Chiều: CS-TD
--           T7 (phụ đạo): Toán-Văn-Anh
--
--    12A2: T2/4/6 Sáng: Anh-Toán-Văn | Chiều: Hóa-Sinh
--           T3/5   Sáng: Lý-Sử-Địa   | Chiều: CS-TD
--           T7 (phụ đạo): Toán-Anh-Văn
--
--  Run: sqlcmd -S localhost,1433 -U sa -P "1" -d eStudentDB
--             -i doc\add-grade12-sem2-timetable.sql
-- =============================================================
USE eStudentDB;
GO

-- ── Lookup IDs ────────────────────────────────────────────────
DECLARE @sem2 INT = (SELECT TOP 1 SemesterId FROM Semesters WHERE Name = N'Semester 2');
DECLARE @c12A1 INT = (SELECT ClassId FROM Classes WHERE Name = N'12A1');
DECLARE @c12A2 INT = (SELECT ClassId FROM Classes WHERE Name = N'12A2');

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

-- Teachers (lấy từ assignment của 12A1)
DECLARE @tId01 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subMath AND ClassId = @c12A1);
DECLARE @tId02 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subLit  AND ClassId = @c12A1);
DECLARE @tId03 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subEng  AND ClassId = @c12A1);
DECLARE @tId04 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subPhy  AND ClassId = @c12A1);
DECLARE @tId05 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subChem AND ClassId = @c12A1);
DECLARE @tId06 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subBio  AND ClassId = @c12A1);
DECLARE @tId07 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subHis  AND ClassId = @c12A1);
DECLARE @tId08 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subGeo  AND ClassId = @c12A1);
DECLARE @tId09 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subCs   AND ClassId = @c12A1);
DECLARE @tId10 UNIQUEIDENTIFIER = (SELECT TOP 1 TeacherId FROM TeacherClassAssignments WHERE SubjectId = @subPe   AND ClassId = @c12A1);

DECLARE @eff2 DATE = '2026-06-01';

-- ── TIMETABLE SLOTS HỌC KỲ 2 ────────────────────────────────
-- DayOfWeek: 1=T2  2=T3  3=T4  4=T5  5=T6  6=T7
-- Periods sáng:  P1=07:30  P2=08:25  P3=09:20
-- Periods chiều: P6=13:00  P7=13:50
INSERT INTO TimetableSlots
    (ClassId, SubjectId, TeacherId, SemesterId, DayOfWeek, PeriodNo, StartTime, EndTime, Room, EffectiveFrom)
VALUES

-- ══════════ 12A1 ══════════
-- T2/4/6 Sáng: Toán(P1) – Văn(P2) – Anh(P3)
-- T2/4/6 Chiều: Lý(P6) – Hóa(P7)
-- T3/5   Sáng: Sinh(P1) – Sử(P2) – Địa(P3)
-- T3/5   Chiều: CS(P6) – TD(P7)
-- T7     Sáng ôn thi: Toán(P1) – Văn(P2) – Anh(P3)

-- 12A1 T2 (Mon)
(@c12A1,@subMath,@tId01,@sem2,1,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subLit, @tId02,@sem2,1,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subEng, @tId03,@sem2,1,3,'09:20','10:05',N'301',@eff2),
(@c12A1,@subPhy, @tId04,@sem2,1,6,'13:00','13:45',N'301',@eff2),
(@c12A1,@subChem,@tId05,@sem2,1,7,'13:50','14:35',N'301',@eff2),

-- 12A1 T3 (Tue)
(@c12A1,@subBio, @tId06,@sem2,2,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subHis, @tId07,@sem2,2,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subGeo, @tId08,@sem2,2,3,'09:20','10:05',N'301',@eff2),
(@c12A1,@subCs,  @tId09,@sem2,2,6,'13:00','13:45',N'301',@eff2),
(@c12A1,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),

-- 12A1 T4 (Wed)
(@c12A1,@subMath,@tId01,@sem2,3,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subLit, @tId02,@sem2,3,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subEng, @tId03,@sem2,3,3,'09:20','10:05',N'301',@eff2),
(@c12A1,@subPhy, @tId04,@sem2,3,6,'13:00','13:45',N'301',@eff2),
(@c12A1,@subChem,@tId05,@sem2,3,7,'13:50','14:35',N'301',@eff2),

-- 12A1 T5 (Thu)
(@c12A1,@subBio, @tId06,@sem2,4,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subHis, @tId07,@sem2,4,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subGeo, @tId08,@sem2,4,3,'09:20','10:05',N'301',@eff2),
(@c12A1,@subCs,  @tId09,@sem2,4,6,'13:00','13:45',N'301',@eff2),
(@c12A1,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),

-- 12A1 T6 (Fri)
(@c12A1,@subMath,@tId01,@sem2,5,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subLit, @tId02,@sem2,5,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subEng, @tId03,@sem2,5,3,'09:20','10:05',N'301',@eff2),
(@c12A1,@subPhy, @tId04,@sem2,5,6,'13:00','13:45',N'301',@eff2),
(@c12A1,@subChem,@tId05,@sem2,5,7,'13:50','14:35',N'301',@eff2),

-- 12A1 T7 (Sat) — Ôn thi tốt nghiệp
(@c12A1,@subMath,@tId01,@sem2,6,1,'07:30','08:15',N'301',@eff2),
(@c12A1,@subLit, @tId02,@sem2,6,2,'08:25','09:10',N'301',@eff2),
(@c12A1,@subEng, @tId03,@sem2,6,3,'09:20','10:05',N'301',@eff2),

-- ══════════ 12A2 ══════════
-- T2/4/6 Sáng: Anh(P1) – Toán(P2) – Văn(P3)
-- T2/4/6 Chiều: Hóa(P6) – Sinh(P7)
-- T3/5   Sáng: Lý(P1) – Sử(P2) – Địa(P3)
-- T3/5   Chiều: CS(P6) – TD(P7)
-- T7     Sáng ôn thi: Toán(P1) – Anh(P2) – Văn(P3)

-- 12A2 T2 (Mon)
(@c12A2,@subEng, @tId03,@sem2,1,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subMath,@tId01,@sem2,1,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subLit, @tId02,@sem2,1,3,'09:20','10:05',N'302',@eff2),
(@c12A2,@subChem,@tId05,@sem2,1,6,'13:00','13:45',N'302',@eff2),
(@c12A2,@subBio, @tId06,@sem2,1,7,'13:50','14:35',N'302',@eff2),

-- 12A2 T3 (Tue)
(@c12A2,@subPhy, @tId04,@sem2,2,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subHis, @tId07,@sem2,2,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subGeo, @tId08,@sem2,2,3,'09:20','10:05',N'302',@eff2),
(@c12A2,@subCs,  @tId09,@sem2,2,6,'13:00','13:45',N'302',@eff2),
(@c12A2,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),

-- 12A2 T4 (Wed)
(@c12A2,@subEng, @tId03,@sem2,3,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subMath,@tId01,@sem2,3,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subLit, @tId02,@sem2,3,3,'09:20','10:05',N'302',@eff2),
(@c12A2,@subChem,@tId05,@sem2,3,6,'13:00','13:45',N'302',@eff2),
(@c12A2,@subBio, @tId06,@sem2,3,7,'13:50','14:35',N'302',@eff2),

-- 12A2 T5 (Thu)
(@c12A2,@subPhy, @tId04,@sem2,4,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subHis, @tId07,@sem2,4,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subGeo, @tId08,@sem2,4,3,'09:20','10:05',N'302',@eff2),
(@c12A2,@subCs,  @tId09,@sem2,4,6,'13:00','13:45',N'302',@eff2),
(@c12A2,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),

-- 12A2 T6 (Fri)
(@c12A2,@subEng, @tId03,@sem2,5,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subMath,@tId01,@sem2,5,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subLit, @tId02,@sem2,5,3,'09:20','10:05',N'302',@eff2),
(@c12A2,@subChem,@tId05,@sem2,5,6,'13:00','13:45',N'302',@eff2),
(@c12A2,@subBio, @tId06,@sem2,5,7,'13:50','14:35',N'302',@eff2),

-- 12A2 T7 (Sat) — Ôn thi tốt nghiệp
(@c12A2,@subMath,@tId01,@sem2,6,1,'07:30','08:15',N'302',@eff2),
(@c12A2,@subEng, @tId03,@sem2,6,2,'08:25','09:10',N'302',@eff2),
(@c12A2,@subLit, @tId02,@sem2,6,3,'09:20','10:05',N'302',@eff2);

-- ── LessonSessions mẫu tuần 06-11 Jul 2026 ──────────────────
-- Lấy teacher userId để dùng cho RecordedBy
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

-- Lấy StudentId của học sinh 12A1 và 12A2
DECLARE @sId17 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU017');
DECLARE @sId18 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU018');
DECLARE @sId19 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU019');
DECLARE @sId20 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU020');
DECLARE @sId21 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU021');
DECLARE @sId22 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU022');
DECLARE @sId23 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU023');
DECLARE @sId24 UNIQUEIDENTIFIER = (SELECT StudentId FROM Students WHERE StudentCode = N'STU024');

-- ──────────────────────────────────────────────────────────────
-- Tuần 1 kỳ 2: 06-Jul (T2) → 11-Jul (T7) — COMPLETED
-- ──────────────────────────────────────────────────────────────

-- 12A1 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subMath,@tId01,'2026-07-06',1,N'301',N'Limits: definition and rules',    N'COMPLETED'),
(@c12A1,@subLit, @tId02,'2026-07-06',2,N'301',N'Analysis of "Tay Tien" poem',      N'COMPLETED'),
(@c12A1,@subEng, @tId03,'2026-07-06',3,N'301',N'IELTS Listening skills',           N'COMPLETED'),
(@c12A1,@subPhy, @tId04,'2026-07-06',6,N'301',N'Electric current and resistance',  N'COMPLETED'),
(@c12A1,@subChem,@tId05,'2026-07-06',7,N'301',N'Carboxylic acids',                 N'COMPLETED');
DECLARE @ls12A1_0706 INT = SCOPE_IDENTITY() - 4;

-- 12A1 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subBio, @tId06,'2026-07-07',1,N'301',N'DNA replication',                  N'COMPLETED'),
(@c12A1,@subHis, @tId07,'2026-07-07',2,N'301',N'Vietnam revolution 1945',          N'COMPLETED'),
(@c12A1,@subGeo, @tId08,'2026-07-07',3,N'301',N'Industrial development in VN',     N'COMPLETED'),
(@c12A1,@subCs,  @tId09,'2026-07-07',6,N'301',N'HTML & CSS fundamentals',          N'COMPLETED'),
(@c12A1,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Swimming warm-up session',         N'COMPLETED');
DECLARE @ls12A1_0707 INT = SCOPE_IDENTITY() - 4;

-- 12A1 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subMath,@tId01,'2026-07-08',1,N'301',N'Derivatives: product rule',        N'COMPLETED'),
(@c12A1,@subLit, @tId02,'2026-07-08',2,N'301',N'"Viet Bac" prose excerpt',          N'COMPLETED'),
(@c12A1,@subEng, @tId03,'2026-07-08',3,N'301',N'IELTS Reading practice',            N'COMPLETED'),
(@c12A1,@subPhy, @tId04,'2026-07-08',6,N'301',N'Ohm law applications',              N'COMPLETED'),
(@c12A1,@subChem,@tId05,'2026-07-08',7,N'301',N'Esters and fats',                   N'COMPLETED');
DECLARE @ls12A1_0708 INT = SCOPE_IDENTITY() - 4;

-- 12A1 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subBio, @tId06,'2026-07-09',1,N'301',N'Protein synthesis',                 N'COMPLETED'),
(@c12A1,@subHis, @tId07,'2026-07-09',2,N'301',N'American war in Vietnam',           N'COMPLETED'),
(@c12A1,@subGeo, @tId08,'2026-07-09',3,N'301',N'Agricultural regions of VN',        N'COMPLETED'),
(@c12A1,@subCs,  @tId09,'2026-07-09',6,N'301',N'JavaScript basics',                 N'COMPLETED'),
(@c12A1,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Athletics - sprint training',       N'COMPLETED');
DECLARE @ls12A1_0709 INT = SCOPE_IDENTITY() - 4;

-- 12A1 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subMath,@tId01,'2026-07-10',1,N'301',N'Integration: anti-derivatives',     N'COMPLETED'),
(@c12A1,@subLit, @tId02,'2026-07-10',2,N'301',N'Essay writing: social issues',      N'COMPLETED'),
(@c12A1,@subEng, @tId03,'2026-07-10',3,N'301',N'IELTS Writing Task 1 graphs',       N'COMPLETED'),
(@c12A1,@subPhy, @tId04,'2026-07-10',6,N'301',N'Kirchhoff circuit laws',            N'COMPLETED'),
(@c12A1,@subChem,@tId05,'2026-07-10',7,N'301',N'Glucose and fructose',              N'COMPLETED');
DECLARE @ls12A1_0710 INT = SCOPE_IDENTITY() - 4;

-- 12A1 T7 11-Jul (ôn thi tốt nghiệp)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subMath,@tId01,'2026-07-11',1,N'301',N'Mock exam review - Calculus',       N'COMPLETED'),
(@c12A1,@subLit, @tId02,'2026-07-11',2,N'301',N'Mock exam review - Essay',          N'COMPLETED'),
(@c12A1,@subEng, @tId03,'2026-07-11',3,N'301',N'Mock exam review - Grammar',        N'COMPLETED');
DECLARE @ls12A1_0711 INT = SCOPE_IDENTITY() - 2;

-- ──────────────────────────────────────────────────────────────
-- 12A2 Tuần 06-11 Jul 2026
-- ──────────────────────────────────────────────────────────────

-- 12A2 T2 06-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subEng, @tId03,'2026-07-06',1,N'302',N'Advanced reading strategies',       N'COMPLETED'),
(@c12A2,@subMath,@tId01,'2026-07-06',2,N'302',N'Definite integrals',                N'COMPLETED'),
(@c12A2,@subLit, @tId02,'2026-07-06',3,N'302',N'"Nguoi lai do song Da" analysis',   N'COMPLETED'),
(@c12A2,@subChem,@tId05,'2026-07-06',6,N'302',N'Amino acids and proteins',          N'COMPLETED'),
(@c12A2,@subBio, @tId06,'2026-07-06',7,N'302',N'Mutation and evolution',            N'COMPLETED');
DECLARE @ls12A2_0706 INT = SCOPE_IDENTITY() - 4;

-- 12A2 T3 07-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subPhy, @tId04,'2026-07-07',1,N'302',N'Magnetic fields and forces',        N'COMPLETED'),
(@c12A2,@subHis, @tId07,'2026-07-07',2,N'302',N'Post-war reconstruction',           N'COMPLETED'),
(@c12A2,@subGeo, @tId08,'2026-07-07',3,N'302',N'Southeast Asian economies',         N'COMPLETED'),
(@c12A2,@subCs,  @tId09,'2026-07-07',6,N'302',N'Database SQL queries',              N'COMPLETED'),
(@c12A2,@subPe,  @tId10,'2026-07-07',7,N'GYM',N'Team sports: football',            N'COMPLETED');
DECLARE @ls12A2_0707 INT = SCOPE_IDENTITY() - 4;

-- 12A2 T4 08-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subEng, @tId03,'2026-07-08',1,N'302',N'IELTS Speaking practice',           N'COMPLETED'),
(@c12A2,@subMath,@tId01,'2026-07-08',2,N'302',N'Volume of revolution',              N'COMPLETED'),
(@c12A2,@subLit, @tId02,'2026-07-08',3,N'302',N'Modern short stories analysis',     N'COMPLETED'),
(@c12A2,@subChem,@tId05,'2026-07-08',6,N'302',N'Polymers and plastics',             N'COMPLETED'),
(@c12A2,@subBio, @tId06,'2026-07-08',7,N'302',N'Natural selection',                 N'COMPLETED');
DECLARE @ls12A2_0708 INT = SCOPE_IDENTITY() - 4;

-- 12A2 T5 09-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subPhy, @tId04,'2026-07-09',1,N'302',N'Electromagnetic induction',         N'COMPLETED'),
(@c12A2,@subHis, @tId07,'2026-07-09',2,N'302',N'Reunification of Vietnam 1975',     N'COMPLETED'),
(@c12A2,@subGeo, @tId08,'2026-07-09',3,N'302',N'Population and urbanization',       N'COMPLETED'),
(@c12A2,@subCs,  @tId09,'2026-07-09',6,N'302',N'Python data structures',            N'COMPLETED'),
(@c12A2,@subPe,  @tId10,'2026-07-09',7,N'GYM',N'Aerobics and flexibility',          N'COMPLETED');
DECLARE @ls12A2_0709 INT = SCOPE_IDENTITY() - 4;

-- 12A2 T6 10-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subEng, @tId03,'2026-07-10',1,N'302',N'Academic writing structure',        N'COMPLETED'),
(@c12A2,@subMath,@tId01,'2026-07-10',2,N'302',N'Applications of integration',       N'COMPLETED'),
(@c12A2,@subLit, @tId02,'2026-07-10',3,N'302',N'Argumentative essay techniques',    N'COMPLETED'),
(@c12A2,@subChem,@tId05,'2026-07-10',6,N'302',N'Review: organic chemistry',         N'COMPLETED'),
(@c12A2,@subBio, @tId06,'2026-07-10',7,N'302',N'Population genetics',               N'COMPLETED');
DECLARE @ls12A2_0710 INT = SCOPE_IDENTITY() - 4;

-- 12A2 T7 11-Jul (ôn thi tốt nghiệp)
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subMath,@tId01,'2026-07-11',1,N'302',N'Mock exam review - Integration',    N'COMPLETED'),
(@c12A2,@subEng, @tId03,'2026-07-11',2,N'302',N'Mock exam review - Writing',        N'COMPLETED'),
(@c12A2,@subLit, @tId02,'2026-07-11',3,N'302',N'Mock exam review - Literature',     N'COMPLETED');
DECLARE @ls12A2_0711 INT = SCOPE_IDENTITY() - 2;

-- ──────────────────────────────────────────────────────────────
-- Tuần 2: 13-Jul (T2) → 18-Jul (T7) — IN PROGRESS / SCHEDULED
-- ──────────────────────────────────────────────────────────────

-- 12A1 T2 13-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subMath,@tId01,'2026-07-13',1,N'301',N'Definite integrals and area',      N'SCHEDULED'),
(@c12A1,@subLit, @tId02,'2026-07-13',2,N'301',N'Contemporary Vietnamese writers',  N'SCHEDULED'),
(@c12A1,@subEng, @tId03,'2026-07-13',3,N'301',N'IELTS Writing Task 2 practice',   N'SCHEDULED'),
(@c12A1,@subPhy, @tId04,'2026-07-13',6,N'301',N'Capacitors and capacitance',      N'SCHEDULED'),
(@c12A1,@subChem,@tId05,'2026-07-13',7,N'301',N'Saccharose and starch',           N'SCHEDULED');

-- 12A1 T3 14-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A1,@subBio, @tId06,'2026-07-14',1,N'301',N'Meiosis and genetic variation',   N'SCHEDULED'),
(@c12A1,@subHis, @tId07,'2026-07-14',2,N'301',N'Doi Moi economic reforms',        N'SCHEDULED'),
(@c12A1,@subGeo, @tId08,'2026-07-14',3,N'301',N'Fishing industry in Vietnam',     N'SCHEDULED'),
(@c12A1,@subCs,  @tId09,'2026-07-14',6,N'301',N'Functions and algorithms',        N'SCHEDULED'),
(@c12A1,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Volleyball tournament',           N'SCHEDULED');

-- 12A2 T2 13-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subEng, @tId03,'2026-07-13',1,N'302',N'Opinion essays - environment',    N'SCHEDULED'),
(@c12A2,@subMath,@tId01,'2026-07-13',2,N'302',N'Trigonometric integrals',         N'SCHEDULED'),
(@c12A2,@subLit, @tId02,'2026-07-13',3,N'302',N'Poetry comparison techniques',    N'SCHEDULED'),
(@c12A2,@subChem,@tId05,'2026-07-13',6,N'302',N'Petroleum and fuels',             N'SCHEDULED'),
(@c12A2,@subBio, @tId06,'2026-07-13',7,N'302',N'Speciation and extinction',       N'SCHEDULED');

-- 12A2 T3 14-Jul
INSERT INTO LessonSessions (ClassId,SubjectId,TeacherId,SessionDate,PeriodNo,Room,Topic,Status) VALUES
(@c12A2,@subPhy, @tId04,'2026-07-14',1,N'302',N'AC circuits fundamentals',        N'SCHEDULED'),
(@c12A2,@subHis, @tId07,'2026-07-14',2,N'302',N'Foreign policy of Vietnam',       N'SCHEDULED'),
(@c12A2,@subGeo, @tId08,'2026-07-14',3,N'302',N'Transport infrastructure',        N'SCHEDULED'),
(@c12A2,@subCs,  @tId09,'2026-07-14',6,N'302',N'Sorting algorithms',              N'SCHEDULED'),
(@c12A2,@subPe,  @tId10,'2026-07-14',7,N'GYM',N'Basketball techniques',           N'SCHEDULED');

-- ── Attendance cho tuần 1 (06-10 Jul) ───────────────────────

-- 12A1 T2 06-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0706,  @sId17,N'PRESENT',@uT01),(@ls12A1_0706,  @sId18,N'PRESENT',@uT01),(@ls12A1_0706,  @sId19,N'LATE',  @uT01),(@ls12A1_0706,  @sId20,N'PRESENT',@uT01),
(@ls12A1_0706+1,@sId17,N'PRESENT',@uT02),(@ls12A1_0706+1,@sId18,N'PRESENT',@uT02),(@ls12A1_0706+1,@sId19,N'PRESENT',@uT02),(@ls12A1_0706+1,@sId20,N'PRESENT',@uT02),
(@ls12A1_0706+2,@sId17,N'PRESENT',@uT03),(@ls12A1_0706+2,@sId18,N'ABSENT', @uT03),(@ls12A1_0706+2,@sId19,N'PRESENT',@uT03),(@ls12A1_0706+2,@sId20,N'PRESENT',@uT03),
(@ls12A1_0706+3,@sId17,N'PRESENT',@uT04),(@ls12A1_0706+3,@sId18,N'PRESENT',@uT04),(@ls12A1_0706+3,@sId19,N'PRESENT',@uT04),(@ls12A1_0706+3,@sId20,N'PRESENT',@uT04),
(@ls12A1_0706+4,@sId17,N'PRESENT',@uT05),(@ls12A1_0706+4,@sId18,N'PRESENT',@uT05),(@ls12A1_0706+4,@sId19,N'PRESENT',@uT05),(@ls12A1_0706+4,@sId20,N'PRESENT',@uT05);

-- 12A1 T3 07-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0707,  @sId17,N'PRESENT',@uT06),(@ls12A1_0707,  @sId18,N'PRESENT',@uT06),(@ls12A1_0707,  @sId19,N'PRESENT',@uT06),(@ls12A1_0707,  @sId20,N'PRESENT',@uT06),
(@ls12A1_0707+1,@sId17,N'LATE',  @uT07),(@ls12A1_0707+1,@sId18,N'PRESENT',@uT07),(@ls12A1_0707+1,@sId19,N'PRESENT',@uT07),(@ls12A1_0707+1,@sId20,N'PRESENT',@uT07),
(@ls12A1_0707+2,@sId17,N'PRESENT',@uT08),(@ls12A1_0707+2,@sId18,N'PRESENT',@uT08),(@ls12A1_0707+2,@sId19,N'PRESENT',@uT08),(@ls12A1_0707+2,@sId20,N'ABSENT', @uT08),
(@ls12A1_0707+3,@sId17,N'PRESENT',@uT09),(@ls12A1_0707+3,@sId18,N'PRESENT',@uT09),(@ls12A1_0707+3,@sId19,N'PRESENT',@uT09),(@ls12A1_0707+3,@sId20,N'PRESENT',@uT09),
(@ls12A1_0707+4,@sId17,N'PRESENT',@uT10),(@ls12A1_0707+4,@sId18,N'PRESENT',@uT10),(@ls12A1_0707+4,@sId19,N'PRESENT',@uT10),(@ls12A1_0707+4,@sId20,N'PRESENT',@uT10);

-- 12A1 T4 08-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0708,  @sId17,N'PRESENT',@uT01),(@ls12A1_0708,  @sId18,N'PRESENT',@uT01),(@ls12A1_0708,  @sId19,N'PRESENT',@uT01),(@ls12A1_0708,  @sId20,N'PRESENT',@uT01),
(@ls12A1_0708+1,@sId17,N'PRESENT',@uT02),(@ls12A1_0708+1,@sId18,N'PRESENT',@uT02),(@ls12A1_0708+1,@sId19,N'LATE',  @uT02),(@ls12A1_0708+1,@sId20,N'PRESENT',@uT02),
(@ls12A1_0708+2,@sId17,N'PRESENT',@uT03),(@ls12A1_0708+2,@sId18,N'PRESENT',@uT03),(@ls12A1_0708+2,@sId19,N'PRESENT',@uT03),(@ls12A1_0708+2,@sId20,N'PRESENT',@uT03),
(@ls12A1_0708+3,@sId17,N'PRESENT',@uT04),(@ls12A1_0708+3,@sId18,N'ABSENT', @uT04),(@ls12A1_0708+3,@sId19,N'PRESENT',@uT04),(@ls12A1_0708+3,@sId20,N'PRESENT',@uT04),
(@ls12A1_0708+4,@sId17,N'PRESENT',@uT05),(@ls12A1_0708+4,@sId18,N'PRESENT',@uT05),(@ls12A1_0708+4,@sId19,N'PRESENT',@uT05),(@ls12A1_0708+4,@sId20,N'PRESENT',@uT05);

-- 12A1 T5 09-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0709,  @sId17,N'PRESENT',@uT06),(@ls12A1_0709,  @sId18,N'PRESENT',@uT06),(@ls12A1_0709,  @sId19,N'PRESENT',@uT06),(@ls12A1_0709,  @sId20,N'PRESENT',@uT06),
(@ls12A1_0709+1,@sId17,N'PRESENT',@uT07),(@ls12A1_0709+1,@sId18,N'PRESENT',@uT07),(@ls12A1_0709+1,@sId19,N'PRESENT',@uT07),(@ls12A1_0709+1,@sId20,N'PRESENT',@uT07),
(@ls12A1_0709+2,@sId17,N'PRESENT',@uT08),(@ls12A1_0709+2,@sId18,N'LATE',  @uT08),(@ls12A1_0709+2,@sId19,N'PRESENT',@uT08),(@ls12A1_0709+2,@sId20,N'PRESENT',@uT08),
(@ls12A1_0709+3,@sId17,N'PRESENT',@uT09),(@ls12A1_0709+3,@sId18,N'PRESENT',@uT09),(@ls12A1_0709+3,@sId19,N'ABSENT', @uT09),(@ls12A1_0709+3,@sId20,N'PRESENT',@uT09),
(@ls12A1_0709+4,@sId17,N'PRESENT',@uT10),(@ls12A1_0709+4,@sId18,N'PRESENT',@uT10),(@ls12A1_0709+4,@sId19,N'PRESENT',@uT10),(@ls12A1_0709+4,@sId20,N'PRESENT',@uT10);

-- 12A1 T6 10-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0710,  @sId17,N'PRESENT',@uT01),(@ls12A1_0710,  @sId18,N'PRESENT',@uT01),(@ls12A1_0710,  @sId19,N'PRESENT',@uT01),(@ls12A1_0710,  @sId20,N'PRESENT',@uT01),
(@ls12A1_0710+1,@sId17,N'PRESENT',@uT02),(@ls12A1_0710+1,@sId18,N'PRESENT',@uT02),(@ls12A1_0710+1,@sId19,N'PRESENT',@uT02),(@ls12A1_0710+1,@sId20,N'ABSENT', @uT02),
(@ls12A1_0710+2,@sId17,N'PRESENT',@uT03),(@ls12A1_0710+2,@sId18,N'PRESENT',@uT03),(@ls12A1_0710+2,@sId19,N'PRESENT',@uT03),(@ls12A1_0710+2,@sId20,N'PRESENT',@uT03),
(@ls12A1_0710+3,@sId17,N'PRESENT',@uT04),(@ls12A1_0710+3,@sId18,N'PRESENT',@uT04),(@ls12A1_0710+3,@sId19,N'LATE',  @uT04),(@ls12A1_0710+3,@sId20,N'PRESENT',@uT04),
(@ls12A1_0710+4,@sId17,N'PRESENT',@uT05),(@ls12A1_0710+4,@sId18,N'PRESENT',@uT05),(@ls12A1_0710+4,@sId19,N'PRESENT',@uT05),(@ls12A1_0710+4,@sId20,N'PRESENT',@uT05);

-- 12A1 T7 11-Jul (ôn thi)
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A1_0711,  @sId17,N'PRESENT',@uT01),(@ls12A1_0711,  @sId18,N'PRESENT',@uT01),(@ls12A1_0711,  @sId19,N'PRESENT',@uT01),(@ls12A1_0711,  @sId20,N'PRESENT',@uT01),
(@ls12A1_0711+1,@sId17,N'PRESENT',@uT02),(@ls12A1_0711+1,@sId18,N'LATE',  @uT02),(@ls12A1_0711+1,@sId19,N'PRESENT',@uT02),(@ls12A1_0711+1,@sId20,N'PRESENT',@uT02),
(@ls12A1_0711+2,@sId17,N'PRESENT',@uT03),(@ls12A1_0711+2,@sId18,N'PRESENT',@uT03),(@ls12A1_0711+2,@sId19,N'PRESENT',@uT03),(@ls12A1_0711+2,@sId20,N'PRESENT',@uT03);

-- 12A2 T2 06-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0706,  @sId21,N'PRESENT',@uT03),(@ls12A2_0706,  @sId22,N'PRESENT',@uT03),(@ls12A2_0706,  @sId23,N'PRESENT',@uT03),(@ls12A2_0706,  @sId24,N'LATE',  @uT03),
(@ls12A2_0706+1,@sId21,N'PRESENT',@uT01),(@ls12A2_0706+1,@sId22,N'ABSENT', @uT01),(@ls12A2_0706+1,@sId23,N'PRESENT',@uT01),(@ls12A2_0706+1,@sId24,N'PRESENT',@uT01),
(@ls12A2_0706+2,@sId21,N'PRESENT',@uT02),(@ls12A2_0706+2,@sId22,N'PRESENT',@uT02),(@ls12A2_0706+2,@sId23,N'PRESENT',@uT02),(@ls12A2_0706+2,@sId24,N'PRESENT',@uT02),
(@ls12A2_0706+3,@sId21,N'PRESENT',@uT05),(@ls12A2_0706+3,@sId22,N'PRESENT',@uT05),(@ls12A2_0706+3,@sId23,N'LATE',  @uT05),(@ls12A2_0706+3,@sId24,N'PRESENT',@uT05),
(@ls12A2_0706+4,@sId21,N'PRESENT',@uT06),(@ls12A2_0706+4,@sId22,N'PRESENT',@uT06),(@ls12A2_0706+4,@sId23,N'PRESENT',@uT06),(@ls12A2_0706+4,@sId24,N'PRESENT',@uT06);

-- 12A2 T3 07-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0707,  @sId21,N'PRESENT',@uT04),(@ls12A2_0707,  @sId22,N'PRESENT',@uT04),(@ls12A2_0707,  @sId23,N'PRESENT',@uT04),(@ls12A2_0707,  @sId24,N'PRESENT',@uT04),
(@ls12A2_0707+1,@sId21,N'PRESENT',@uT07),(@ls12A2_0707+1,@sId22,N'PRESENT',@uT07),(@ls12A2_0707+1,@sId23,N'ABSENT', @uT07),(@ls12A2_0707+1,@sId24,N'PRESENT',@uT07),
(@ls12A2_0707+2,@sId21,N'LATE',  @uT08),(@ls12A2_0707+2,@sId22,N'PRESENT',@uT08),(@ls12A2_0707+2,@sId23,N'PRESENT',@uT08),(@ls12A2_0707+2,@sId24,N'PRESENT',@uT08),
(@ls12A2_0707+3,@sId21,N'PRESENT',@uT09),(@ls12A2_0707+3,@sId22,N'PRESENT',@uT09),(@ls12A2_0707+3,@sId23,N'PRESENT',@uT09),(@ls12A2_0707+3,@sId24,N'PRESENT',@uT09),
(@ls12A2_0707+4,@sId21,N'PRESENT',@uT10),(@ls12A2_0707+4,@sId22,N'PRESENT',@uT10),(@ls12A2_0707+4,@sId23,N'PRESENT',@uT10),(@ls12A2_0707+4,@sId24,N'PRESENT',@uT10);

-- 12A2 T4 08-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0708,  @sId21,N'PRESENT',@uT03),(@ls12A2_0708,  @sId22,N'PRESENT',@uT03),(@ls12A2_0708,  @sId23,N'PRESENT',@uT03),(@ls12A2_0708,  @sId24,N'PRESENT',@uT03),
(@ls12A2_0708+1,@sId21,N'PRESENT',@uT01),(@ls12A2_0708+1,@sId22,N'LATE',  @uT01),(@ls12A2_0708+1,@sId23,N'PRESENT',@uT01),(@ls12A2_0708+1,@sId24,N'PRESENT',@uT01),
(@ls12A2_0708+2,@sId21,N'PRESENT',@uT02),(@ls12A2_0708+2,@sId22,N'PRESENT',@uT02),(@ls12A2_0708+2,@sId23,N'PRESENT',@uT02),(@ls12A2_0708+2,@sId24,N'ABSENT', @uT02),
(@ls12A2_0708+3,@sId21,N'PRESENT',@uT05),(@ls12A2_0708+3,@sId22,N'PRESENT',@uT05),(@ls12A2_0708+3,@sId23,N'PRESENT',@uT05),(@ls12A2_0708+3,@sId24,N'PRESENT',@uT05),
(@ls12A2_0708+4,@sId21,N'PRESENT',@uT06),(@ls12A2_0708+4,@sId22,N'PRESENT',@uT06),(@ls12A2_0708+4,@sId23,N'LATE',  @uT06),(@ls12A2_0708+4,@sId24,N'PRESENT',@uT06);

-- 12A2 T5 09-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0709,  @sId21,N'PRESENT',@uT04),(@ls12A2_0709,  @sId22,N'PRESENT',@uT04),(@ls12A2_0709,  @sId23,N'PRESENT',@uT04),(@ls12A2_0709,  @sId24,N'PRESENT',@uT04),
(@ls12A2_0709+1,@sId21,N'PRESENT',@uT07),(@ls12A2_0709+1,@sId22,N'PRESENT',@uT07),(@ls12A2_0709+1,@sId23,N'PRESENT',@uT07),(@ls12A2_0709+1,@sId24,N'PRESENT',@uT07),
(@ls12A2_0709+2,@sId21,N'PRESENT',@uT08),(@ls12A2_0709+2,@sId22,N'PRESENT',@uT08),(@ls12A2_0709+2,@sId23,N'ABSENT', @uT08),(@ls12A2_0709+2,@sId24,N'PRESENT',@uT08),
(@ls12A2_0709+3,@sId21,N'PRESENT',@uT09),(@ls12A2_0709+3,@sId22,N'LATE',  @uT09),(@ls12A2_0709+3,@sId23,N'PRESENT',@uT09),(@ls12A2_0709+3,@sId24,N'PRESENT',@uT09),
(@ls12A2_0709+4,@sId21,N'PRESENT',@uT10),(@ls12A2_0709+4,@sId22,N'PRESENT',@uT10),(@ls12A2_0709+4,@sId23,N'PRESENT',@uT10),(@ls12A2_0709+4,@sId24,N'PRESENT',@uT10);

-- 12A2 T6 10-Jul
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0710,  @sId21,N'PRESENT',@uT03),(@ls12A2_0710,  @sId22,N'PRESENT',@uT03),(@ls12A2_0710,  @sId23,N'LATE',  @uT03),(@ls12A2_0710,  @sId24,N'PRESENT',@uT03),
(@ls12A2_0710+1,@sId21,N'PRESENT',@uT01),(@ls12A2_0710+1,@sId22,N'PRESENT',@uT01),(@ls12A2_0710+1,@sId23,N'PRESENT',@uT01),(@ls12A2_0710+1,@sId24,N'PRESENT',@uT01),
(@ls12A2_0710+2,@sId21,N'PRESENT',@uT02),(@ls12A2_0710+2,@sId22,N'ABSENT', @uT02),(@ls12A2_0710+2,@sId23,N'PRESENT',@uT02),(@ls12A2_0710+2,@sId24,N'PRESENT',@uT02),
(@ls12A2_0710+3,@sId21,N'PRESENT',@uT05),(@ls12A2_0710+3,@sId22,N'PRESENT',@uT05),(@ls12A2_0710+3,@sId23,N'PRESENT',@uT05),(@ls12A2_0710+3,@sId24,N'PRESENT',@uT05),
(@ls12A2_0710+4,@sId21,N'PRESENT',@uT06),(@ls12A2_0710+4,@sId22,N'PRESENT',@uT06),(@ls12A2_0710+4,@sId23,N'PRESENT',@uT06),(@ls12A2_0710+4,@sId24,N'PRESENT',@uT06);

-- 12A2 T7 11-Jul (ôn thi)
INSERT INTO AttendanceRecords (LessonSessionId,StudentId,Status,RecordedBy) VALUES
(@ls12A2_0711,  @sId21,N'PRESENT',@uT01),(@ls12A2_0711,  @sId22,N'PRESENT',@uT01),(@ls12A2_0711,  @sId23,N'PRESENT',@uT01),(@ls12A2_0711,  @sId24,N'PRESENT',@uT01),
(@ls12A2_0711+1,@sId21,N'PRESENT',@uT03),(@ls12A2_0711+1,@sId22,N'PRESENT',@uT03),(@ls12A2_0711+1,@sId23,N'ABSENT', @uT03),(@ls12A2_0711+1,@sId24,N'PRESENT',@uT03),
(@ls12A2_0711+2,@sId21,N'PRESENT',@uT02),(@ls12A2_0711+2,@sId22,N'PRESENT',@uT02),(@ls12A2_0711+2,@sId23,N'PRESENT',@uT02),(@ls12A2_0711+2,@sId24,N'LATE',  @uT02);

-- ── DONE ──────────────────────────────────────────────────────
PRINT N'';
PRINT N'=======================================================';
PRINT N'  Lịch học kỳ 2 khối 12 đã được thêm thành công!';
PRINT N'';
PRINT N'  Timetable slots:';
PRINT N'    12A1: 28 slots HK2 (T2-T6 sáng+chiều, T7 ôn thi)';
PRINT N'    12A2: 28 slots HK2 (T2-T6 sáng+chiều, T7 ôn thi)';
PRINT N'';
PRINT N'  Lesson Sessions:';
PRINT N'    Tuần 1 (06-11 Jul): COMPLETED + Attendance records';
PRINT N'    Tuần 2 (13-14 Jul): SCHEDULED (chờ điểm danh)';
PRINT N'=======================================================';
GO
