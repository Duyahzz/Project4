import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models.dart';
import '../student/student_dashboard.dart';
import '../profile/profile_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final parentUserId = auth.currentUser?.userId ?? '';

    setState(() => _isLoading = true);

    try {
      // 1. Get parents list to find parentId corresponding to this userId
      final parentsRes = await api.getParents();
      final parentRecord = parentsRes.firstWhere(
        (p) => p.userId == parentUserId,
        orElse: () => ApiParent(parentId: '', userId: ''),
      );

      final String parentId = parentRecord.parentId ?? '';
      if (parentId.isEmpty) {
        setState(() {
          _children = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Get parent-student links to find studentIds linked to parentId
      final linksRes = await api.getParentLinks();
      final childLinks = linksRes.where((l) => l.id.parentId == parentId).toList();

      // 3. Get students details to match studentIds
      final studentsRes = await api.getStudents();

      final List<Map<String, dynamic>> childList = [];
      for (var link in childLinks) {
        final studentId = link.id.studentId;
        final studentObj = studentsRes.firstWhere(
          (s) => s.studentId == studentId,
          orElse: () => ApiStudent(studentId: studentId),
        );

        final String uId = studentObj.userId ?? '';
        final String fullName = api.userNamesMap[uId] ?? 'Student $studentId';
        final String studentCode = studentObj.studentCode ?? '';

        childList.add({
          'studentId': studentId,
          'fullName': fullName,
          'studentCode': studentCode,
          'relationship': link.relationship ?? 'Child',
        });
      }

      setState(() {
        _children = childList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching parent children: $e');
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
        title: Text(lang.t('parent_dashboard')),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Text(lang.isVietnamese ? '🇻🇳' : '🇬🇧', style: const TextStyle(fontSize: 20)),
            onPressed: () => lang.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChildren,
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Card(
                    color: const Color(0xFF0A2540),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('parent_portal'),
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.fullName ?? lang.t('parent'),
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
                                  lang.t('guardian_role'),
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
                  Text(
                    lang.t('linked_students_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                  ),
                  const SizedBox(height: 8),
                  _children.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                lang.t('no_linked_students'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _children.length,
                            itemBuilder: (context, idx) {
                              final child = _children[idx];
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0x1F0A2540),
                                    child: Icon(Icons.face, color: Color(0xFF0A2540)),
                                  ),
                                  title: Text(child['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${lang.t('roll_no')}: ${child['studentCode']} • ${lang.t('relationship')}: ${child['relationship']}'),
                                  trailing: const Icon(Icons.arrow_forward),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChildMonitorScreen(
                                          studentId: child['studentId'],
                                          fullName: child['fullName'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

// ─── CHILD MONITOR SCREEN ───
class ChildMonitorScreen extends StatefulWidget {
  final String studentId;
  final String fullName;
  const ChildMonitorScreen({Key? key, required this.studentId, required this.fullName}) : super(key: key);

  @override
  State<ChildMonitorScreen> createState() => _ChildMonitorScreenState();
}

class _ChildMonitorScreenState extends State<ChildMonitorScreen> {
  bool _isLoading = true;
  List<TimetableSlot> _timetable = [];
  List<ScoreDetail> _marks = [];
  List<AttendanceRecord> _attendance = [];

  @override
  void initState() {
    super.initState();
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        api.getTimetable(null),
        api.getStudentMarks(widget.studentId),
        api.getAttendanceForStudent(widget.studentId),
      ]);

      setState(() {
        _timetable = results[0] as List<TimetableSlot>;
        _marks = results[1] as List<ScoreDetail>;
        _attendance = results[2] as List<AttendanceRecord>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching child details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fullName),
          backgroundColor: const Color(0xFF0A2540),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: const Color(0xFFED7D31),
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFED7D31),
            tabs: [
              Tab(icon: const Icon(Icons.calendar_today_outlined), text: lang.t('timetable')),
              Tab(icon: const Icon(Icons.grade_outlined), text: lang.t('marks')),
              Tab(icon: const Icon(Icons.check_circle_outline), text: lang.t('attendance')),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTimetableTab(lang),
                  _buildMarksTab(lang),
                  _buildAttendanceTab(lang),
                ],
              ),
      ),
    );
  }

  Widget _buildTimetableTab(LanguageProvider lang) {
    final Map<String, List<TimetableSlot>> daySlots = {
      'Mon': [], 'Tue': [], 'Wed': [], 'Thu': [], 'Fri': [], 'Sat': []
    };
    for (var slot in _timetable) {
      daySlots[slot.day]?.add(slot);
    }
    for (var key in daySlots.keys) {
      daySlots[key]?.sort((a, b) => a.period.compareTo(b.period));
    }

    final dayLabels = lang.isVietnamese
        ? {'Mon': 'T.2', 'Tue': 'T.3', 'Wed': 'T.4', 'Thu': 'T.5', 'Fri': 'T.6', 'Sat': 'T.7'}
        : {'Mon': 'Mon', 'Tue': 'Tue', 'Wed': 'Wed', 'Thu': 'Thu', 'Fri': 'Fri', 'Sat': 'Sat'};

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: TabBar(
          isScrollable: true,
          labelColor: const Color(0xFFED7D31),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFED7D31),
          tabs: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((d) => Tab(text: dayLabels[d] ?? d))
              .toList(),
        ),
        body: TabBarView(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
            final slots = daySlots[day] ?? [];
            if (slots.isEmpty) {
              return Center(child: Text(lang.t('no_classes_today')));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: slots.length,
              itemBuilder: (context, idx) {
                final slot = slots[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF0A2540),
                          radius: 22,
                          child: Text(
                            '${slot.period}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${lang.t('teacher_key')}: ${slot.teacher}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${slot.startTime} - ${slot.endTime}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED7D31).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Room ${slot.room}',
                            style: const TextStyle(color: Color(0xFFED7D31), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMarksTab(LanguageProvider lang) {
    if (_marks.isEmpty) {
      return Center(child: Text(lang.t('no_marks_child')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _marks.length,
      itemBuilder: (context, idx) {
        final mark = _marks[idx];
        final score = mark.scoreReceived;
        final color = score >= 8.0 ? Colors.green : score >= 5.0 ? Colors.orange : Colors.red;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Text(score.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            title: Text(mark.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${mark.description}\n${lang.t('date_label')}: ${mark.date.substring(0, 10)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(LanguageProvider lang) {
    if (_attendance.isEmpty) {
      return Center(child: Text(lang.t('no_attendance_child')));
    }

    final statusLabels = {
      'PRESENT': lang.t('present'),
      'ABSENT': lang.t('absent'),
      'LATE': lang.t('late'),
      'EXCUSED': lang.t('excused'),
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      itemBuilder: (context, idx) {
        final r = _attendance[idx];
        Color color = Colors.grey;
        if (r.status == 'PRESENT') color = Colors.green;
        else if (r.status == 'ABSENT') color = Colors.red;
        else if (r.status == 'LATE') color = Colors.orange;
        else if (r.status == 'EXCUSED') color = Colors.blue;

        return Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline, color: color),
            title: Text(statusLabels[r.status] ?? r.status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            subtitle: Text('Session ID: ${r.lessonSessionId}${r.note != null ? '\n${r.note}' : ''}'),
          ),
        );
      },
    );
  }
}
