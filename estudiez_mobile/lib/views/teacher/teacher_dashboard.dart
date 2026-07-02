import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _isLoading = true;
  List<SchoolClass> _classes = [];
  List<ChatGroup> _chatGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        api.getClasses(),
        api.getChatGroups(),
      ]);

      setState(() {
        _classes = results[0] as List<SchoolClass>;
        _chatGroups = results[1] as List<ChatGroup>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching teacher dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('teacher_dashboard')),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Text(lang.isVietnamese ? '🇻🇳' : '🇬🇧', style: const TextStyle(fontSize: 20)),
            onPressed: () => lang.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          IconButton(
            tooltip: lang.t('my_profile'),
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    color: const Color(0xFF0A2540),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('homeroom_portal'),
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.fullName ?? lang.t('teacher'),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFED7D31),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user?.subject ?? lang.t('teacher'),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assigned / Manage Classes
                  Text(
                    lang.t('my_classes'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                  ),
                  const SizedBox(height: 8),
                  _classes.isEmpty
                      ? Text(lang.t('no_classes'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _classes.length,
                          itemBuilder: (context, idx) {
                            final cls = _classes[idx];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0x1F0A2540),
                                  child: Icon(Icons.school, color: Color(0xFF0A2540)),
                                ),
                                title: Text('${lang.t('class_label')} ${cls.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${lang.t('grade_label')} ${cls.grade} • ${lang.t('year_label')}: ${cls.year}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClassDetailScreen(schoolClass: cls),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),

                  // Chat groups
                  Text(
                    lang.t('class_chat_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                  ),
                  const SizedBox(height: 8),
                  _chatGroups.isEmpty
                      ? Text(lang.t('no_chat'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _chatGroups.length,
                          itemBuilder: (context, idx) {
                            final chat = _chatGroups[idx];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFED7D31),
                                  child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                                ),
                                title: Text(chat.name),
                                subtitle: Text('${lang.t('type_label')}: ${chat.type.toUpperCase()}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(groupId: int.parse(chat.id), groupName: chat.name),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ─── CLASS DETAIL SCREEN ───
class ClassDetailScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const ClassDetailScreen({Key? key, required this.schoolClass}) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<TimetableSlot> _timetable = [];
  List<LessonSession> _lessons = [];
  List<Exam> _assessments = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final cId = widget.schoolClass.classId;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.getStudentsForClass(cId),
        api.getTimetable(cId),
        api.getLessons(cId),
        api.getAssessments(cId),
      ]);

      setState(() {
        _students = results[0] as List<Map<String, dynamic>>;
        _timetable = results[1] as List<TimetableSlot>;
        _lessons = results[2] as List<LessonSession>;
        _assessments = results[3] as List<Exam>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching class details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${lang.t('class_label')} ${widget.schoolClass.name}'),
          backgroundColor: const Color(0xFF0A2540),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: const Color(0xFFED7D31),
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFED7D31),
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.people_outline), text: lang.t('roster_tab')),
              Tab(icon: const Icon(Icons.calendar_today_outlined), text: lang.t('timetable_tab')),
              Tab(icon: const Icon(Icons.check_circle_outline), text: lang.t('attendance_tab')),
              Tab(icon: const Icon(Icons.grade_outlined), text: lang.t('assessments_tab')),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRosterTab(lang),
                  _buildTimetableTab(lang),
                  _buildAttendanceTab(lang),
                  _buildAssessmentsTab(lang),
                ],
              ),
      ),
    );
  }

  Widget _buildRosterTab(LanguageProvider lang) {
    if (_students.isEmpty) {
      return Center(child: Text(lang.t('no_roster')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, idx) {
        final s = _students[idx];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0x1F0A2540),
              child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(s['fullName'] ?? ''),
            subtitle: Text('${lang.t('roll_no')}: ${s['studentCode']}'),
          ),
        );
      },
    );
  }

  Widget _buildTimetableTab(LanguageProvider lang) {
    if (_timetable.isEmpty) {
      return Center(child: Text(lang.t('no_timetable')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timetable.length,
      itemBuilder: (context, idx) {
        final s = _timetable[idx];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0A2540),
              child: Text(s.day, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text(s.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${lang.t('period_short')} ${s.period} • Room ${s.room}'),
            trailing: Text(s.teacher, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(LanguageProvider lang) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A2540),
        onPressed: () => _createNewLessonSession(lang),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _lessons.isEmpty
          ? Center(child: Text(lang.t('no_attendance_sessions')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lessons.length,
              itemBuilder: (context, idx) {
                final l = _lessons[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.event_note, color: Colors.white),
                    ),
                    title: Text(l.topic ?? lang.t('add_lesson'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${lang.t('date_label')}: ${l.sessionDate} • ${lang.t('period_short')}: ${l.periodNo}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonAttendanceScreen(
                              lessonSession: l,
                              students: _students,
                            ),
                          ),
                        ).then((_) => _fetchDetails());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7D31),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(lang.t('roster_button')),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _createNewLessonSession(LanguageProvider lang) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;

    final topicController = TextEditingController();
    int period = 1;
    String dateStr = DateTime.now().toString().substring(0, 10);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(lang.t('add_lesson')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: InputDecoration(labelText: lang.t('topic_label')),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${lang.t('period_label')}:'),
                  DropdownButton<int>(
                    value: period,
                    items: List.generate(5, (index) => index + 1)
                        .map((p) => DropdownMenuItem(value: p, child: Text('$p')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => period = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await api.createLessonSession(LessonSession(
                  lessonSessionId: 0,
                  classId: widget.schoolClass.classId,
                  subjectId: 1,
                  teacherId: auth.currentUser?.userId ?? '',
                  sessionDate: dateStr,
                  periodNo: period,
                  room: '101',
                  topic: topicController.text.trim().isEmpty ? lang.t('add_lesson') : topicController.text.trim(),
                  status: 'SCHEDULED',
                ));
                if (success != null && mounted) {
                  Navigator.pop(context);
                  _fetchDetails();
                }
              },
              child: Text(lang.t('create')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentsTab(LanguageProvider lang) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A2540),
        onPressed: () => _createNewAssessment(lang),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _assessments.isEmpty
          ? Center(child: Text(lang.t('no_assessments')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _assessments.length,
              itemBuilder: (context, idx) {
                final a = _assessments[idx];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.assessment, color: Colors.white),
                    ),
                    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${lang.t('type_label')}: ${a.subject} • ${lang.t('date_label')}: ${a.date.substring(0, 10)}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssessmentGradingScreen(
                              exam: a,
                              students: _students,
                            ),
                          ),
                        ).then((_) => _fetchDetails());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2540),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(lang.t('grade_button')),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _createNewAssessment(LanguageProvider lang) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;

    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('add_assessment_label')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(labelText: lang.t('title_label')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await api.createAssessment(
                widget.schoolClass.classId,
                titleController.text.trim().isEmpty ? 'Quiz' : titleController.text.trim(),
                1,
                1,
                DateTime.now().toIso8601String().substring(0, 10),
              );

              if (success && mounted) {
                Navigator.pop(context);
                _fetchDetails();
              }
            },
            child: Text(lang.t('create')),
          ),
        ],
      ),
    );
  }
}

// ─── ATTENDANCE GRADING PANEL SCREEN ───
class LessonAttendanceScreen extends StatefulWidget {
  final LessonSession lessonSession;
  final List<Map<String, dynamic>> students;

  const LessonAttendanceScreen({
    Key? key,
    required this.lessonSession,
    required this.students,
  }) : super(key: key);

  @override
  State<LessonAttendanceScreen> createState() => _LessonAttendanceScreenState();
}

class _LessonAttendanceScreenState extends State<LessonAttendanceScreen> {
  bool _isLoading = true;
  final Map<String, String> _attendanceMap = {}; // studentId -> status

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    try {
      final records = await api.getLessonsAttendance(widget.lessonSession.lessonSessionId);
      setState(() {
        for (var s in widget.students) {
          final sId = s['studentId'] ?? '';
          final match = records.firstWhere((r) => r.studentId == sId,
              orElse: () => AttendanceRecord(attendanceRecordId: 0, lessonSessionId: 0, studentId: sId, status: 'PRESENT'));
          _attendanceMap[sId] = match.status;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  void _saveAll() async {
    setState(() => _isLoading = true);
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final futures = _attendanceMap.entries.map((entry) {
        return api.saveAttendanceRecord(
          widget.lessonSession.lessonSessionId,
          entry.key,
          entry.value,
        );
      });

      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('attendance_saved')), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonSession.topic ?? lang.t('attendance')),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAll,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (context, idx) {
                final student = widget.students[idx];
                final sId = student['studentId'] ?? '';
                final currentStatus = _attendanceMap[sId] ?? 'PRESENT';

                // Map status to translated label
                final statusLabels = {
                  'PRESENT': lang.t('present'),
                  'ABSENT': lang.t('absent'),
                  'LATE': lang.t('late'),
                  'EXCUSED': lang.t('excused'),
                };

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['fullName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'].map((status) {
                            Color activeColor = Colors.grey;
                            if (status == 'PRESENT') activeColor = Colors.green;
                            else if (status == 'ABSENT') activeColor = Colors.red;
                            else if (status == 'LATE') activeColor = Colors.orange;
                            else if (status == 'EXCUSED') activeColor = Colors.blue;

                            return ChoiceChip(
                              label: Text(statusLabels[status] ?? status, style: const TextStyle(fontSize: 12)),
                              selected: currentStatus == status,
                              selectedColor: activeColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: currentStatus == status ? activeColor : Colors.black87,
                                fontWeight: currentStatus == status ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _attendanceMap[sId] = status);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── ASSESSMENT GRADING PANEL SCREEN ───
class AssessmentGradingScreen extends StatefulWidget {
  final Exam exam;
  final List<Map<String, dynamic>> students;

  const AssessmentGradingScreen({
    Key? key,
    required this.exam,
    required this.students,
  }) : super(key: key);

  @override
  State<AssessmentGradingScreen> createState() => _AssessmentGradingScreenState();
}

class _AssessmentGradingScreenState extends State<AssessmentGradingScreen> {
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    try {
      final marks = await api.getMarksForAssessment(widget.exam.id);
      setState(() {
        for (var s in widget.students) {
          final sId = s['studentId'] ?? '';
          final match = marks.firstWhere((m) => m.studentEmail == api.userEmailsMap[s['userId']],
              orElse: () => ScoreDetail(id: 0, studentEmail: '', classId: '', subject: '', testId: '', description: '', date: '', scoreReceived: 0.0, semesterId: 1));

          _controllers[sId] = TextEditingController(
            text: match.id != 0 ? match.scoreReceived.toString() : '',
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading marks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveAll() async {
    setState(() => _isLoading = true);
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final futures = _controllers.entries.map((entry) {
        final score = double.tryParse(entry.value.text) ?? 0.0;
        return api.saveStudentMark(
          widget.exam.id,
          entry.key,
          score,
        );
      });

      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('marks_saved')), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving marks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.name),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAll,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (context, idx) {
                final student = widget.students[idx];
                final sId = student['studentId'] ?? '';
                final controller = _controllers[sId];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['fullName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text('${lang.t('roll_no')}: ${student['studentCode']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0.0',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
