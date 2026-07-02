import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  bool _isInitialLoading = true;
  
  List<TimetableSlot> _timetable = [];
  List<ScoreDetail> _marks = [];
  List<AttendanceRecord> _attendance = [];
  List<Resource> _resources = [];
  List<NotificationItem> _notifications = [];
  List<Helpline> _helplines = [];
  List<ChatGroup> _chatGroups = [];
  List<LessonSession> _lessons = [];
  int _selectedSemester = 1;
  int _selectedTimetableSemester = 1;
  String _className = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final String currentUserId = auth.currentUser?.userId ?? '';

    setState(() => _isInitialLoading = true);

    try {
      String resolvedStudentId = currentUserId;
      try {
        final studentsList = await api.getStudents();
        for (var s in studentsList) {
          if (s.userId == currentUserId) {
            resolvedStudentId = s.studentId;
            break;
          }
        }
      } catch (e) {
        print('Error resolving studentId: $e');
      }

      int? resolvedClassId;
      try {
        final enrollments = await api.getEnrollments();
        for (var e in enrollments) {
          if (e['studentId']?.toString() == resolvedStudentId && e['status'] == 'ACTIVE') {
            resolvedClassId = e['classId'] as int?;
            break;
          }
        }
      } catch (e) {
        print('Error resolving classId: $e');
      }

      String activeClassName = '';
      try {
        final classesList = await api.getClasses();
        for (var c in classesList) {
          if (c.classId == resolvedClassId) {
            activeClassName = c.name;
            break;
          }
        }
      } catch (e) {
        print('Error resolving className: $e');
      }

      final results = await Future.wait<dynamic>([
        api.getTimetable(resolvedClassId),
        api.getStudentMarks(resolvedStudentId),
        api.getAttendanceForStudent(resolvedStudentId),
        api.getResources(resolvedClassId),
        api.getNotifications(),
        api.getContacts(),
        api.getChatGroups(),
        api.getLessons(resolvedClassId ?? 0),
      ]);

      setState(() {
        _timetable = results[0] as List<TimetableSlot>;
        _marks = results[1] as List<ScoreDetail>;
        _attendance = results[2] as List<AttendanceRecord>;
        _resources = results[3] as List<Resource>;
        _notifications = results[4] as List<NotificationItem>;
        _helplines = results[5] as List<Helpline>;
        final allChats = results[6] as List<ChatGroup>;
        _chatGroups = allChats.where((g) => 
          g.classId == resolvedClassId?.toString() && 
          g.type == 'student-teacher'
        ).toList();
        _lessons = results[7] as List<LessonSession>;
        _className = activeClassName;
        _isInitialLoading = false;
      });
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() => _isInitialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.currentUser;

    final List<Widget> children = [
      _buildHomeTab(user, lang),
      _buildTimetableTab(),
      _buildMarksTab(),
      _buildAttendanceTab(),
      _buildResourcesTab(lang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle(lang)),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Text(lang.isVietnamese ? '🇻🇳' : '🇬🇧', style: const TextStyle(fontSize: 20)),
            onPressed: () => lang.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentData,
          ),
          IconButton(
            tooltip: 'My Profile',
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
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFED7D31),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: lang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), activeIcon: const Icon(Icons.calendar_today), label: lang.t('timetable')),
          BottomNavigationBarItem(icon: const Icon(Icons.grade_outlined), activeIcon: const Icon(Icons.grade), label: lang.t('marks')),
          BottomNavigationBarItem(icon: const Icon(Icons.check_circle_outline), activeIcon: const Icon(Icons.check_circle), label: lang.t('attendance')),
          BottomNavigationBarItem(icon: const Icon(Icons.folder_open_outlined), activeIcon: const Icon(Icons.folder), label: lang.t('resources')),
        ],
      ),
    );
  }

  String _getTabTitle(LanguageProvider lang) {
    switch (_currentIndex) {
      case 0: return lang.t('student_dashboard');
      case 1: return lang.t('class_timetable');
      case 2: return lang.t('academic_performance');
      case 3: return lang.t('attendance_history');
      case 4: return lang.t('study_resources');
      default: return lang.t('app_name');
    }
  }

  // ─── HOME TAB ───
  Widget _buildHomeTab(User? user, LanguageProvider lang) {
    // Filter marks and attendance based on selected semester
    final filteredMarks = _marks.where((m) => m.semesterId == _selectedSemester).toList();
    
    final filteredAttendance = _attendance.where((a) {
      LessonSession? lesson;
      for (var l in _lessons) {
        if (l.lessonSessionId == a.lessonSessionId) {
          lesson = l;
          break;
        }
      }
      if (lesson == null) return false;
      
      int sem = 1;
      try {
        final date = DateTime.parse(lesson.sessionDate.substring(0, 10));
        if (date.isAfter(DateTime(2026, 1, 15))) {
          sem = 2;
        }
      } catch (_) {}
      return sem == _selectedSemester;
    }).toList();

    final double gpa = filteredMarks.isEmpty 
        ? 0.0 
        : filteredMarks.map((m) => m.scoreReceived).reduce((a, b) => a + b) / filteredMarks.length;
    
    final int presentCount = filteredAttendance.where((a) => a.status == 'PRESENT').length;
    final int absentCount = filteredAttendance.where((a) => a.status == 'ABSENT').length;
    final double attendanceRate = filteredAttendance.isEmpty 
        ? 100.0 
        : (presentCount / filteredAttendance.length) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Card(
            color: const Color(0xFF0A2540),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('welcome_back'),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Student',
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
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_className.isNotEmpty ? _className : 'Grade 10'} • THPT',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSemesterSelector(lang),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: lang.t('gpa_score'),
                  value: gpa.toStringAsFixed(2),
                  subtitle: '${filteredMarks.length} assessments',
                  icon: Icons.analytics_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: lang.t('attendance_rate'),
                  value: '${attendanceRate.toStringAsFixed(1)}%',
                  subtitle: '$presentCount present / $absentCount absent',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Announcements / Notifications
          Text(lang.t('recent_announcements'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
          const SizedBox(height: 8),
          _notifications.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No new notifications')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length > 3 ? 3 : _notifications.length,
                  itemBuilder: (context, idx) {
                    final item = _notifications[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x1F0A2540),
                          child: Icon(Icons.notifications_active, color: Color(0xFF0A2540)),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${item.body}\nSent by: ${item.sender} • ${item.date}', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
          // Chat Group Redirect
          Text(lang.t('my_chat_groups'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
          const SizedBox(height: 8),
          _chatGroups.isEmpty
              ? Text(lang.t('no_chat'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chatGroups.length,
                  itemBuilder: (context, idx) {
                    final group = _chatGroups[idx];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFED7D31),
                          child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                        ),
                        title: Text(group.name),
                        subtitle: Text('Type: ${group.type.toUpperCase()}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(groupId: int.parse(group.id), groupName: group.name),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
          // Support / Helpline
          Text(lang.t('helpline_support'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
          const SizedBox(height: 8),
          Row(
            children: _helplines.map((h) {
              return Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Icon(Icons.phone_in_talk, color: Color(0xFFED7D31)),
                        const SizedBox(height: 8),
                        Text(h.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(h.phone, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── TIMETABLE TAB ───
  Widget _buildTimetableTab() {
    final lang = Provider.of<LanguageProvider>(context);

    // Filter timetable slots by selected semester
    final semesterString = _selectedTimetableSemester == 1 ? 'S1-2025' : 'S2-2025';
    final filteredSlots = _timetable.where((s) => s.semesterId == semesterString).toList();

    final Map<String, List<TimetableSlot>> daySlots = {
      'Mon': [], 'Tue': [], 'Wed': [], 'Thu': [], 'Fri': [], 'Sat': []
    };
    for (var slot in filteredSlots) {
      daySlots[slot.day]?.add(slot);
    }
    for (var key in daySlots.keys) {
      daySlots[key]?.sort((a, b) => a.period.compareTo(b.period));
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: _buildTimetableSemesterSelector(lang),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFED7D31),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFED7D31),
            tabs: [
              Tab(text: 'Mon'),
              Tab(text: 'Tue'),
              Tab(text: 'Wed'),
              Tab(text: 'Thu'),
              Tab(text: 'Fri'),
              Tab(text: 'Sat'),
            ],
          ),
        ),
        body: TabBarView(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
            final slots = daySlots[day] ?? [];
            if (slots.isEmpty) {
              return const Center(child: Text('No classes scheduled for today'));
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
                        // Period circle
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
                              Text('${lang.t('teacher')}: ${slot.teacher}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
                        // Room badge
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

  // ─── MARKS TAB ───
  Widget _buildMarksTab() {
    final lang = Provider.of<LanguageProvider>(context);
    final filtered = _marks.where((m) => m.semesterId == _selectedSemester).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSemesterSelector(lang),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No academic marks found for this semester.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final mark = filtered[idx];
                    final score = mark.scoreReceived;
                    final color = score >= 8.0 ? Colors.green : score >= 5.0 ? Colors.orange : Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(mark.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${mark.description}\nDate: ${mark.date.substring(0, 10)}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── ATTENDANCE TAB ───
  Widget _buildAttendanceTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final lang = Provider.of<LanguageProvider>(context);

    final filtered = _attendance.where((a) {
      LessonSession? lesson;
      for (var l in _lessons) {
        if (l.lessonSessionId == a.lessonSessionId) {
          lesson = l;
          break;
        }
      }
      if (lesson == null) return false;
      int sem = 1;
      try {
        final date = DateTime.parse(lesson.sessionDate.substring(0, 10));
        if (date.isAfter(DateTime(2026, 1, 15))) {
          sem = 2;
        }
      } catch (_) {}
      return sem == _selectedSemester;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSemesterSelector(lang),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No attendance history found for this semester.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final record = filtered[idx];
                    final status = record.status;

                    Color color = Colors.grey;
                    IconData icon = Icons.help_outline;
                    if (status == 'PRESENT') { color = Colors.green; icon = Icons.check_circle_outline; }
                    else if (status == 'ABSENT') { color = Colors.red; icon = Icons.cancel_outlined; }
                    else if (status == 'LATE') { color = Colors.orange; icon = Icons.watch_later_outlined; }
                    else if (status == 'EXCUSED') { color = Colors.blue; icon = Icons.info_outline; }

                    // Find the corresponding lesson session details
                    LessonSession? lesson;
                    for (var l in _lessons) {
                      if (l.lessonSessionId == record.lessonSessionId) {
                        lesson = l;
                        break;
                      }
                    }

                    String subjectName = 'Lesson';
                    String date = 'N/A';
                    String periodAndRoom = 'Period: N/A';
                    if (lesson != null) {
                      subjectName = api.subjectMap[lesson.subjectId] ?? 'Subject ${lesson.subjectId}';
                      date = lesson.sessionDate.length >= 10 
                          ? lesson.sessionDate.substring(0, 10) 
                          : lesson.sessionDate;

                      // Look up class hours for this period from the timetable
                      String timeString = '';
                      for (var slot in _timetable) {
                        if (slot.period == lesson.periodNo && slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
                          timeString = ' (${slot.startTime} - ${slot.endTime})';
                          break;
                        }
                      }
                      periodAndRoom = 'Period ${lesson.periodNo}$timeString${lesson.room != null ? ' - Room ${lesson.room}' : ''}';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(icon, color: color, size: 28),
                        title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Status: $status • $periodAndRoom\nDate: $date${record.note != null ? '\nNote: ${record.note}' : ''}',
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        trailing: record.arrivedAt != null 
                            ? Text(record.arrivedAt!.substring(11, 16), style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── RESOURCES TAB ───
  Widget _buildResourcesTab(LanguageProvider lang) {
    if (_resources.isEmpty) {
      return Center(child: Text(lang.t('study_resources')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _resources.length,
      itemBuilder: (context, idx) {
        final res = _resources[idx];
        
        IconData icon = Icons.insert_drive_file_outlined;
        Color color = Colors.blue;
        if (res.type == 'video') { icon = Icons.play_circle_outline; color = Colors.red; }
        else if (res.type == 'external-link') { icon = Icons.language_outlined; color = Colors.orange; }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(icon, color: color, size: 28),
            title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Subject: ${res.subject} • By: ${res.addedBy}'),
            trailing: const Icon(Icons.download_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading: ${res.url}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSemesterSelector(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSemester = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedSemester == 1 ? const Color(0xFFED7D31) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    lang.t('semester_1'),
                    style: TextStyle(
                      color: _selectedSemester == 1 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSemester = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedSemester == 2 ? const Color(0xFFED7D31) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    lang.t('semester_2'),
                    style: TextStyle(
                      color: _selectedSemester == 2 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSemesterSelector(LanguageProvider lang) {
    final dateRange = _selectedTimetableSemester == 1 
        ? '01/09/2025 - 15/01/2026' 
        : '16/01/2026 - 30/06/2026';
        
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTimetableSemester = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedTimetableSemester == 1 ? const Color(0xFFED7D31) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        lang.t('semester_1'),
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedTimetableSemester == 1 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTimetableSemester = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedTimetableSemester == 2 ? const Color(0xFFED7D31) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        lang.t('semester_2'),
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedTimetableSemester == 2 ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateRange,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
