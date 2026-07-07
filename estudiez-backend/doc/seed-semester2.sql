-- ============================================================
-- SEED: Semester 2 Timetable Data (2026-06-01 → 2026-11-06)
-- Thêm lịch học kỳ 2 cho 4 lớp: 10A1, 10A2, 11A1, 11A2
-- EffectiveFrom: 2026-06-01 (ngày bắt đầu kỳ 2)
-- DayOfWeek: 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat
-- Periods:   P1=07:30-08:15 P2=08:25-09:10 P3=09:20-10:05
--            P4=10:15-11:00 P5=11:10-11:55
--            P6=13:00-13:45 P7=13:50-14:35
-- ============================================================

USE eStudentDB;

-- Lấy SemesterId kỳ 2
DECLARE @sem2 INT = (SELECT TOP 1 SemesterId FROM Semesters WHERE Name = N'Semester 2');

-- Lấy ClassId
DECLARE @c10A1 INT = (SELECT ClassId FROM Classes WHERE Name = N'10A1');
DECLARE @c10A2 INT = (SELECT ClassId FROM Classes WHERE Name = N'10A2');
DECLARE @c11A1 INT = (SELECT ClassId FROM Classes WHERE Name = N'11A1');
DECLARE @c11A2 INT = (SELECT ClassId FROM Classes WHERE Name = N'11A2');

-- Lấy SubjectId
DECLARE @subMath INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Mathematics');
DECLARE @subLit  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Literature');
DECLARE @subEng  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'English');
DECLARE @subPhy  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Physics');
DECLARE @subChem INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Chemistry');
DECLARE @subBio  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Biology');
DECLARE @subHis  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'History');
DECLARE @subGeo  INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Geography');
DECLARE @subCs   INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Computer Science');
DECLARE @subPe   INT = (SELECT SubjectId FROM Subjects WHERE Name = N'Physical Education');

-- Lấy TeacherId từ TeacherClassAssignments
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

DECLARE @eff2 DATE = '2026-06-01';

-- ── SEMESTER 2 TIMETABLE ─────────────────────────────────────────────────────
-- Kỳ 2: buổi sáng P1-P3, buổi chiều P6-P7, thứ 7 phụ đạo sáng
INSERT INTO TimetableSlots (ClassId,SubjectId,TeacherId,SemesterId,DayOfWeek,PeriodNo,StartTime,EndTime,Room,EffectiveFrom) VALUES
-- ─── 10A1 ─────────────────────────────────────────────────────────────────
-- 10A1 Mon
(@c10A1,@subMath,@tId01,@sem2,1,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subLit, @tId02,@sem2,1,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subEng, @tId03,@sem2,1,3,'09:20','10:05',N'101',@eff2),
(@c10A1,@subPhy, @tId04,@sem2,1,6,'13:00','13:45',N'101',@eff2),
(@c10A1,@subChem,@tId05,@sem2,1,7,'13:50','14:35',N'101',@eff2),
-- 10A1 Tue
(@c10A1,@subBio, @tId06,@sem2,2,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subHis, @tId07,@sem2,2,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subGeo, @tId08,@sem2,2,3,'09:20','10:05',N'101',@eff2),
(@c10A1,@subCs,  @tId09,@sem2,2,6,'13:00','13:45',N'101',@eff2),
(@c10A1,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),
-- 10A1 Wed
(@c10A1,@subMath,@tId01,@sem2,3,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subLit, @tId02,@sem2,3,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subEng, @tId03,@sem2,3,3,'09:20','10:05',N'101',@eff2),
(@c10A1,@subPhy, @tId04,@sem2,3,6,'13:00','13:45',N'101',@eff2),
(@c10A1,@subChem,@tId05,@sem2,3,7,'13:50','14:35',N'101',@eff2),
-- 10A1 Thu
(@c10A1,@subBio, @tId06,@sem2,4,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subHis, @tId07,@sem2,4,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subGeo, @tId08,@sem2,4,3,'09:20','10:05',N'101',@eff2),
(@c10A1,@subCs,  @tId09,@sem2,4,6,'13:00','13:45',N'101',@eff2),
(@c10A1,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),
-- 10A1 Fri
(@c10A1,@subMath,@tId01,@sem2,5,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subLit, @tId02,@sem2,5,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subEng, @tId03,@sem2,5,3,'09:20','10:05',N'101',@eff2),
(@c10A1,@subPhy, @tId04,@sem2,5,6,'13:00','13:45',N'101',@eff2),
(@c10A1,@subChem,@tId05,@sem2,5,7,'13:50','14:35',N'101',@eff2),
-- 10A1 Sat (phụ đạo sáng)
(@c10A1,@subMath,@tId01,@sem2,6,1,'07:30','08:15',N'101',@eff2),
(@c10A1,@subLit, @tId02,@sem2,6,2,'08:25','09:10',N'101',@eff2),
(@c10A1,@subEng, @tId03,@sem2,6,3,'09:20','10:05',N'101',@eff2),

-- ─── 10A2 ─────────────────────────────────────────────────────────────────
-- 10A2 Mon
(@c10A2,@subPhy, @tId04,@sem2,1,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subMath,@tId01,@sem2,1,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subEng, @tId03,@sem2,1,3,'09:20','10:05',N'102',@eff2),
(@c10A2,@subLit, @tId02,@sem2,1,6,'13:00','13:45',N'102',@eff2),
(@c10A2,@subCs,  @tId09,@sem2,1,7,'13:50','14:35',N'102',@eff2),
-- 10A2 Tue
(@c10A2,@subChem,@tId05,@sem2,2,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subBio, @tId06,@sem2,2,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subHis, @tId07,@sem2,2,3,'09:20','10:05',N'102',@eff2),
(@c10A2,@subGeo, @tId08,@sem2,2,6,'13:00','13:45',N'102',@eff2),
(@c10A2,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),
-- 10A2 Wed
(@c10A2,@subPhy, @tId04,@sem2,3,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subMath,@tId01,@sem2,3,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subEng, @tId03,@sem2,3,3,'09:20','10:05',N'102',@eff2),
(@c10A2,@subLit, @tId02,@sem2,3,6,'13:00','13:45',N'102',@eff2),
(@c10A2,@subCs,  @tId09,@sem2,3,7,'13:50','14:35',N'102',@eff2),
-- 10A2 Thu
(@c10A2,@subChem,@tId05,@sem2,4,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subBio, @tId06,@sem2,4,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subHis, @tId07,@sem2,4,3,'09:20','10:05',N'102',@eff2),
(@c10A2,@subGeo, @tId08,@sem2,4,6,'13:00','13:45',N'102',@eff2),
(@c10A2,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),
-- 10A2 Fri
(@c10A2,@subPhy, @tId04,@sem2,5,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subMath,@tId01,@sem2,5,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subEng, @tId03,@sem2,5,3,'09:20','10:05',N'102',@eff2),
(@c10A2,@subLit, @tId02,@sem2,5,6,'13:00','13:45',N'102',@eff2),
(@c10A2,@subCs,  @tId09,@sem2,5,7,'13:50','14:35',N'102',@eff2),
-- 10A2 Sat
(@c10A2,@subPhy, @tId04,@sem2,6,1,'07:30','08:15',N'102',@eff2),
(@c10A2,@subMath,@tId01,@sem2,6,2,'08:25','09:10',N'102',@eff2),
(@c10A2,@subEng, @tId03,@sem2,6,3,'09:20','10:05',N'102',@eff2),

-- ─── 11A1 ─────────────────────────────────────────────────────────────────
-- 11A1 Mon
(@c11A1,@subLit, @tId02,@sem2,1,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subMath,@tId01,@sem2,1,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subEng, @tId03,@sem2,1,3,'09:20','10:05',N'201',@eff2),
(@c11A1,@subPhy, @tId04,@sem2,1,6,'13:00','13:45',N'201',@eff2),
(@c11A1,@subCs,  @tId09,@sem2,1,7,'13:50','14:35',N'201',@eff2),
-- 11A1 Tue
(@c11A1,@subChem,@tId05,@sem2,2,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subBio, @tId06,@sem2,2,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subHis, @tId07,@sem2,2,3,'09:20','10:05',N'201',@eff2),
(@c11A1,@subGeo, @tId08,@sem2,2,6,'13:00','13:45',N'201',@eff2),
(@c11A1,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),
-- 11A1 Wed
(@c11A1,@subLit, @tId02,@sem2,3,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subMath,@tId01,@sem2,3,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subEng, @tId03,@sem2,3,3,'09:20','10:05',N'201',@eff2),
(@c11A1,@subPhy, @tId04,@sem2,3,6,'13:00','13:45',N'201',@eff2),
(@c11A1,@subCs,  @tId09,@sem2,3,7,'13:50','14:35',N'201',@eff2),
-- 11A1 Thu
(@c11A1,@subChem,@tId05,@sem2,4,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subBio, @tId06,@sem2,4,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subHis, @tId07,@sem2,4,3,'09:20','10:05',N'201',@eff2),
(@c11A1,@subGeo, @tId08,@sem2,4,6,'13:00','13:45',N'201',@eff2),
(@c11A1,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),
-- 11A1 Fri
(@c11A1,@subLit, @tId02,@sem2,5,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subMath,@tId01,@sem2,5,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subEng, @tId03,@sem2,5,3,'09:20','10:05',N'201',@eff2),
(@c11A1,@subPhy, @tId04,@sem2,5,6,'13:00','13:45',N'201',@eff2),
(@c11A1,@subCs,  @tId09,@sem2,5,7,'13:50','14:35',N'201',@eff2),
-- 11A1 Sat
(@c11A1,@subLit, @tId02,@sem2,6,1,'07:30','08:15',N'201',@eff2),
(@c11A1,@subMath,@tId01,@sem2,6,2,'08:25','09:10',N'201',@eff2),
(@c11A1,@subEng, @tId03,@sem2,6,3,'09:20','10:05',N'201',@eff2),

-- ─── 11A2 ─────────────────────────────────────────────────────────────────
-- 11A2 Mon
(@c11A2,@subEng, @tId03,@sem2,1,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subLit, @tId02,@sem2,1,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subMath,@tId01,@sem2,1,3,'09:20','10:05',N'202',@eff2),
(@c11A2,@subPhy, @tId04,@sem2,1,6,'13:00','13:45',N'202',@eff2),
(@c11A2,@subBio, @tId06,@sem2,1,7,'13:50','14:35',N'202',@eff2),
-- 11A2 Tue
(@c11A2,@subChem,@tId05,@sem2,2,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subHis, @tId07,@sem2,2,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subGeo, @tId08,@sem2,2,3,'09:20','10:05',N'202',@eff2),
(@c11A2,@subCs,  @tId09,@sem2,2,6,'13:00','13:45',N'202',@eff2),
(@c11A2,@subPe,  @tId10,@sem2,2,7,'13:50','14:35',N'GYM',@eff2),
-- 11A2 Wed
(@c11A2,@subEng, @tId03,@sem2,3,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subLit, @tId02,@sem2,3,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subMath,@tId01,@sem2,3,3,'09:20','10:05',N'202',@eff2),
(@c11A2,@subPhy, @tId04,@sem2,3,6,'13:00','13:45',N'202',@eff2),
(@c11A2,@subBio, @tId06,@sem2,3,7,'13:50','14:35',N'202',@eff2),
-- 11A2 Thu
(@c11A2,@subChem,@tId05,@sem2,4,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subHis, @tId07,@sem2,4,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subGeo, @tId08,@sem2,4,3,'09:20','10:05',N'202',@eff2),
(@c11A2,@subCs,  @tId09,@sem2,4,6,'13:00','13:45',N'202',@eff2),
(@c11A2,@subPe,  @tId10,@sem2,4,7,'13:50','14:35',N'GYM',@eff2),
-- 11A2 Fri
(@c11A2,@subEng, @tId03,@sem2,5,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subLit, @tId02,@sem2,5,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subMath,@tId01,@sem2,5,3,'09:20','10:05',N'202',@eff2),
(@c11A2,@subPhy, @tId04,@sem2,5,6,'13:00','13:45',N'202',@eff2),
(@c11A2,@subBio, @tId06,@sem2,5,7,'13:50','14:35',N'202',@eff2),
-- 11A2 Sat
(@c11A2,@subEng, @tId03,@sem2,6,1,'07:30','08:15',N'202',@eff2),
(@c11A2,@subLit, @tId02,@sem2,6,2,'08:25','09:10',N'202',@eff2),
(@c11A2,@subMath,@tId01,@sem2,6,3,'09:20','10:05',N'202',@eff2);


-- ── ASSESSMENTS KỲ 2 ────────────────────────────────────────────────────────
-- Lấy AssessmentTypeId
DECLARE @atQuiz    INT = (SELECT TOP 1 AssessmentTypeId FROM AssessmentTypes WHERE Name LIKE '%15%' OR AssessmentTypeId = 1);
DECLARE @atMidterm INT = (SELECT TOP 1 AssessmentTypeId FROM AssessmentTypes WHERE Name LIKE '%Mid%' OR AssessmentTypeId = 2);
DECLARE @atFinal   INT = (SELECT TOP 1 AssessmentTypeId FROM AssessmentTypes WHERE Name LIKE '%Final%' OR AssessmentTypeId = 3);

-- Quiz kỳ 2 (tháng 6/2026)
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status) VALUES
(@c10A1,@subMath,@tId01,@sem2,@atQuiz,N'Math Quiz 1',       '2026-06-15',10.0,0.10,'COMPLETED'),
(@c10A1,@subLit, @tId02,@sem2,@atQuiz,N'Lit Quiz 1',        '2026-06-16',10.0,0.10,'COMPLETED'),
(@c10A1,@subEng, @tId03,@sem2,@atQuiz,N'English Quiz 1',    '2026-06-17',10.0,0.10,'COMPLETED'),
(@c10A2,@subMath,@tId01,@sem2,@atQuiz,N'Math Quiz 1',       '2026-06-15',10.0,0.10,'COMPLETED'),
(@c10A2,@subPhy, @tId04,@sem2,@atQuiz,N'Physics Quiz 1',    '2026-06-18',10.0,0.10,'COMPLETED'),
(@c11A1,@subMath,@tId01,@sem2,@atQuiz,N'Math Quiz 1',       '2026-06-16',10.0,0.10,'COMPLETED'),
(@c11A1,@subEng, @tId03,@sem2,@atQuiz,N'English Quiz 1',    '2026-06-17',10.0,0.10,'COMPLETED'),
(@c11A2,@subEng, @tId03,@sem2,@atQuiz,N'English Quiz 1',    '2026-06-19',10.0,0.10,'COMPLETED');

-- Midterm kỳ 2 (tháng 8/2026)
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status) VALUES
(@c10A1,@subMath,@tId01,@sem2,@atMidterm,N'Math Midterm Sem 2',      '2026-08-15',10.0,0.30,'COMPLETED'),
(@c10A1,@subLit, @tId02,@sem2,@atMidterm,N'Lit Midterm Sem 2',       '2026-08-16',10.0,0.30,'COMPLETED'),
(@c10A1,@subEng, @tId03,@sem2,@atMidterm,N'English Midterm Sem 2',   '2026-08-17',10.0,0.30,'COMPLETED'),
(@c10A1,@subPhy, @tId04,@sem2,@atMidterm,N'Physics Midterm Sem 2',   '2026-08-18',10.0,0.30,'COMPLETED'),
(@c10A1,@subChem,@tId05,@sem2,@atMidterm,N'Chemistry Midterm Sem 2', '2026-08-19',10.0,0.30,'COMPLETED'),
(@c10A2,@subMath,@tId01,@sem2,@atMidterm,N'Math Midterm Sem 2',      '2026-08-15',10.0,0.30,'COMPLETED'),
(@c10A2,@subPhy, @tId04,@sem2,@atMidterm,N'Physics Midterm Sem 2',   '2026-08-16',10.0,0.30,'COMPLETED'),
(@c11A1,@subMath,@tId01,@sem2,@atMidterm,N'Math Midterm Sem 2',      '2026-08-15',10.0,0.30,'COMPLETED'),
(@c11A1,@subLit, @tId02,@sem2,@atMidterm,N'Lit Midterm Sem 2',       '2026-08-16',10.0,0.30,'COMPLETED'),
(@c11A1,@subPhy, @tId04,@sem2,@atMidterm,N'Physics Midterm Sem 2',   '2026-08-17',10.0,0.30,'COMPLETED'),
(@c11A2,@subEng, @tId03,@sem2,@atMidterm,N'English Midterm Sem 2',   '2026-08-15',10.0,0.30,'COMPLETED'),
(@c11A2,@subMath,@tId01,@sem2,@atMidterm,N'Math Midterm Sem 2',      '2026-08-16',10.0,0.30,'COMPLETED');

-- Final kỳ 2 (tháng 10/2026)
INSERT INTO Assessments(ClassId,SubjectId,TeacherId,SemesterId,AssessmentTypeId,Title,AssessmentDate,MaxScore,Weight,Status) VALUES
(@c10A1,@subMath,@tId01,@sem2,@atFinal,N'Math Final Sem 2',       '2026-10-15',10.0,0.60,'SCHEDULED'),
(@c10A1,@subLit, @tId02,@sem2,@atFinal,N'Lit Final Sem 2',        '2026-10-16',10.0,0.60,'SCHEDULED'),
(@c10A1,@subEng, @tId03,@sem2,@atFinal,N'English Final Sem 2',    '2026-10-17',10.0,0.60,'SCHEDULED'),
(@c10A1,@subPhy, @tId04,@sem2,@atFinal,N'Physics Final Sem 2',    '2026-10-18',10.0,0.60,'SCHEDULED'),
(@c10A1,@subChem,@tId05,@sem2,@atFinal,N'Chemistry Final Sem 2',  '2026-10-19',10.0,0.60,'SCHEDULED'),
(@c10A2,@subMath,@tId01,@sem2,@atFinal,N'Math Final Sem 2',       '2026-10-15',10.0,0.60,'SCHEDULED'),
(@c10A2,@subPhy, @tId04,@sem2,@atFinal,N'Physics Final Sem 2',    '2026-10-16',10.0,0.60,'SCHEDULED'),
(@c11A1,@subMath,@tId01,@sem2,@atFinal,N'Math Final Sem 2',       '2026-10-15',10.0,0.60,'SCHEDULED'),
(@c11A1,@subLit, @tId02,@sem2,@atFinal,N'Lit Final Sem 2',        '2026-10-16',10.0,0.60,'SCHEDULED'),
(@c11A2,@subEng, @tId03,@sem2,@atFinal,N'English Final Sem 2',    '2026-10-17',10.0,0.60,'SCHEDULED'),
(@c11A2,@subMath,@tId01,@sem2,@atFinal,N'Math Final Sem 2',       '2026-10-18',10.0,0.60,'SCHEDULED');

-- ── SAMPLE MARKS KỲ 2 (Quiz + Midterm) ─────────────────────────────────────
-- Lấy students từ enrollments
DECLARE @s1 UNIQUEIDENTIFIER, @s2 UNIQUEIDENTIFIER, @s3 UNIQUEIDENTIFIER, @s4 UNIQUEIDENTIFIER;
SELECT @s1 = MIN(StudentId) FROM ClassEnrollments WHERE ClassId = @c10A1;
SELECT @s2 = MIN(StudentId) FROM ClassEnrollments WHERE ClassId = @c10A1 AND StudentId > @s1;
SELECT @s3 = MIN(StudentId) FROM ClassEnrollments WHERE ClassId = @c10A1 AND StudentId > @s2;
SELECT @s4 = MIN(StudentId) FROM ClassEnrollments WHERE ClassId = @c10A1 AND StudentId > @s3;

-- Lấy assessmentId vừa tạo
DECLARE @qMath10A1 INT = (SELECT TOP 1 AssessmentId FROM Assessments WHERE SemesterId=@sem2 AND ClassId=@c10A1 AND SubjectId=@subMath AND Title LIKE N'%Quiz%');
DECLARE @mMath10A1 INT = (SELECT TOP 1 AssessmentId FROM Assessments WHERE SemesterId=@sem2 AND ClassId=@c10A1 AND SubjectId=@subMath AND Title LIKE N'%Midterm%');
DECLARE @mLit10A1  INT = (SELECT TOP 1 AssessmentId FROM Assessments WHERE SemesterId=@sem2 AND ClassId=@c10A1 AND SubjectId=@subLit  AND Title LIKE N'%Midterm%');
DECLARE @mEng10A1  INT = (SELECT TOP 1 AssessmentId FROM Assessments WHERE SemesterId=@sem2 AND ClassId=@c10A1 AND SubjectId=@subEng  AND Title LIKE N'%Midterm%');

-- Quiz Math scores
IF @qMath10A1 IS NOT NULL AND @s1 IS NOT NULL
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,GradedAt,GradedBy) VALUES
(@qMath10A1,@s1,9.0,'2026-02-10',@tId01),(@qMath10A1,@s2,7.5,'2026-02-10',@tId01),
(@qMath10A1,@s3,8.0,'2026-02-10',@tId01),(@qMath10A1,@s4,6.0,'2026-02-10',@tId01);

-- Midterm Math scores
IF @mMath10A1 IS NOT NULL AND @s1 IS NOT NULL
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,GradedAt,GradedBy) VALUES
(@mMath10A1,@s1,8.5,'2026-03-18',@tId01),(@mMath10A1,@s2,7.0,'2026-03-18',@tId01),
(@mMath10A1,@s3,9.0,'2026-03-18',@tId01),(@mMath10A1,@s4,6.5,'2026-03-18',@tId01);

-- Midterm Literature scores
IF @mLit10A1 IS NOT NULL AND @s1 IS NOT NULL
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,GradedAt,GradedBy) VALUES
(@mLit10A1,@s1,7.5,'2026-03-19',@tId02),(@mLit10A1,@s2,8.0,'2026-03-19',@tId02),
(@mLit10A1,@s3,6.5,'2026-03-19',@tId02),(@mLit10A1,@s4,7.0,'2026-03-19',@tId02);

-- Midterm English scores
IF @mEng10A1 IS NOT NULL AND @s1 IS NOT NULL
INSERT INTO StudentMarks(AssessmentId,StudentId,Score,GradedAt,GradedBy) VALUES
(@mEng10A1,@s1,8.0,'2026-03-20',@tId03),(@mEng10A1,@s2,9.0,'2026-03-20',@tId03),
(@mEng10A1,@s3,7.5,'2026-03-20',@tId03),(@mEng10A1,@s4,8.5,'2026-03-20',@tId03);

-- ── VERIFY ─────────────────────────────────────────────────────────────────
PRINT N'========== SEMESTER 2 SEED COMPLETED ==========';
SELECT 
  'Sem2 Data Summary' AS [Report],
  (SELECT COUNT(*) FROM TimetableSlots WHERE SemesterId = @sem2) AS [Timetable Slots],
  (SELECT COUNT(*) FROM Assessments WHERE SemesterId = @sem2) AS [Assessments],
  (SELECT COUNT(*) FROM StudentMarks sm JOIN Assessments a ON sm.AssessmentId = a.AssessmentId WHERE a.SemesterId = @sem2) AS [Student Marks];
