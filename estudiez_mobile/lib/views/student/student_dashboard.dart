import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_list_screen.dart';

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
  int? _resolvedClassId;

  DateTime? _lastReadNotificationsTime;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadLastReadNotifsTime();
    _fetchStudentData();
    _startNotificationTimer();
  }

  Future<void> _loadLastReadNotifsTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_read_notifications_timestamp');
    if (ms != null) {
      setState(() {
        _lastReadNotificationsTime = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    }
  }

  Future<void> _updateLastReadNotifsTime() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_notifications_timestamp', now.millisecondsSinceEpoch);
    setState(() {
      _lastReadNotificationsTime = now;
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _silentFetchStudentData();
    });
  }

  Future<void> _silentFetchStudentData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final String currentUserId = auth.currentUser?.userId ?? '';

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

      final studentEmail = auth.currentUser?.email;
      final rawNotifs = results[4] as List<NotificationItem>;
      final filteredNotifs = rawNotifs.where((n) {
        final aud = n.audience.toLowerCase();
        return aud == 'all' || 
               (aud == 'student' && n.target?.toLowerCase() == studentEmail?.toLowerCase()) ||
               (aud == 'class' && n.target == resolvedClassId?.toString());
      }).toList();
      filteredNotifs.sort((a, b) => b.id.compareTo(a.id));

      if (mounted) {
        setState(() {
          _timetable = results[0] as List<TimetableSlot>;
          _marks = results[1] as List<ScoreDetail>;
          _attendance = results[2] as List<AttendanceRecord>;
          _resources = results[3] as List<Resource>;
          _notifications = filteredNotifs;
          _helplines = results[5] as List<Helpline>;
          final allChats = results[6] as List<ChatGroup>;
          _chatGroups = allChats.where((g) => 
            g.classId == resolvedClassId?.toString() && 
            g.type == 'student-teacher'
          ).toList();
          _lessons = results[7] as List<LessonSession>;
          _className = activeClassName;
          _resolvedClassId = resolvedClassId;
        });
      }
    } catch (e) {
      print('Error silently fetching student data: $e');
    }
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

        final studentEmail = auth.currentUser?.email;
        final rawNotifs = results[4] as List<NotificationItem>;
        final filteredNotifs = rawNotifs.where((n) {
          final aud = n.audience.toLowerCase();
          return aud == 'all' || 
                 (aud == 'student' && n.target?.toLowerCase() == studentEmail?.toLowerCase()) ||
                 (aud == 'class' && n.target == resolvedClassId?.toString());
        }).toList();
        filteredNotifs.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        _timetable = results[0] as List<TimetableSlot>;
        _marks = results[1] as List<ScoreDetail>;
        _attendance = results[2] as List<AttendanceRecord>;
        _resources = results[3] as List<Resource>;
        _notifications = filteredNotifs;
        _helplines = results[5] as List<Helpline>;
        final allChats = results[6] as List<ChatGroup>;
        _chatGroups = allChats.where((g) => 
          g.classId == resolvedClassId?.toString() && 
          g.type == 'student-teacher'
        ).toList();
        _lessons = results[7] as List<LessonSession>;
        _className = activeClassName;
        _resolvedClassId = resolvedClassId;
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

    int unreadCount = 0;
    if (_lastReadNotificationsTime == null) {
      unreadCount = _notifications.length;
    } else {
      unreadCount = _notifications.where((n) {
        try {
          final notifDate = DateTime.parse(n.createdAt);
          return notifDate.isAfter(_lastReadNotificationsTime!);
        } catch (_) {
          return false;
        }
      }).length;
    }

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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () async {
                  try {
                    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                    final rawNotifs = await api.getNotifications();
                    final studentEmail = Provider.of<AuthProvider>(context, listen: false).currentUser?.email;
                    final filteredNotifs = rawNotifs.where((n) {
                      final aud = n.audience.toLowerCase();
                      return aud == 'all' || 
                             (aud == 'student' && n.target?.toLowerCase() == studentEmail?.toLowerCase()) ||
                             (aud == 'class' && n.target == _resolvedClassId?.toString());
                    }).toList();
                    filteredNotifs.sort((a, b) => b.id.compareTo(a.id));
                    setState(() {
                      _notifications = filteredNotifs;
                    });
                  } catch (e) {
                    debugPrint('Error refreshing notifications: $e');
                  }

                  await _updateLastReadNotifsTime();

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationListScreen(notifications: _notifications),
                    ),
                  );

                  if (result != null) {
                    await _fetchStudentData();

                    int? tabVal;
                    if (result is int) {
                      tabVal = result;
                    } else if (result is Map && result['tabIndex'] is int) {
                      tabVal = result['tabIndex'] as int;
                    }
                    if (tabVal != null && tabVal >= 0) {
                      if (_marks.isNotEmpty) {
                        final sorted = List<ScoreDetail>.from(_marks);
                        sorted.sort((a, b) => b.date.compareTo(a.date));
                        setState(() {
                          _selectedSemester = sorted.first.semesterId;
                          _currentIndex = tabVal!;
                        });
                      } else {
                        setState(() {
                          _currentIndex = tabVal!;
                        });
                      }
                    }
                  }
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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

    return RefreshIndicator(
      onRefresh: _fetchStudentData,
      color: const Color(0xFFED7D31),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    final localized = localizeNotification(item.title, item.body, lang.isVietnamese);
                    final dispTitle = localized['title'] ?? item.title;
                    final dispBody = localized['body'] ?? item.body;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x1F0A2540),
                          child: Icon(Icons.notifications_active, color: Color(0xFF0A2540)),
                        ),
                        title: Text(dispTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('$dispBody\nSent by: ${item.sender} • ${item.date}', style: const TextStyle(fontSize: 12)),
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
    ), // SingleChildScrollView
    ); // RefreshIndicator
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

  List<String> _getTimetableDates() {
    final startS1 = DateTime(2025, 12, 1);
    final endS1 = DateTime(2026, 5, 1);
    final startS2 = DateTime(2026, 6, 1);
    final endS2 = DateTime(2026, 11, 6);

    DateTime baseDate;
    final now = DateTime.now();

    if (_selectedTimetableSemester == 1) {
      if (now.isAfter(startS1) && now.isBefore(endS1)) {
        baseDate = now;
      } else {
        baseDate = startS1;
      }
    } else {
      if (now.isAfter(startS2) && now.isBefore(endS2)) {
        baseDate = now;
      } else {
        baseDate = startS2;
      }
    }

    final weekday = baseDate.weekday;
    final monday = baseDate.subtract(Duration(days: weekday - 1));

    final list = <String>[];
    for (int i = 0; i < 6; i++) {
      final date = monday.add(Duration(days: i));
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = date.month.toString().padLeft(2, '0');
      list.add('$dayStr/$monthStr');
    }
    return list;
  }

  Widget _buildTabLabel(String day, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(fontSize: 10)),
        ],
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

    final dates = _getTimetableDates();
    final today = DateTime.now().weekday; // Mon=1, ..., Sun=7
    final initialIndex = (today >= 1 && today <= 6) ? (today - 1) : 0;

    return DefaultTabController(
      length: 6,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: _buildTimetableSemesterSelector(lang),
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFFED7D31),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFED7D31),
            tabs: [
              Tab(child: _buildTabLabel('Mon', dates[0])),
              Tab(child: _buildTabLabel('Tue', dates[1])),
              Tab(child: _buildTabLabel('Wed', dates[2])),
              Tab(child: _buildTabLabel('Thu', dates[3])),
              Tab(child: _buildTabLabel('Fri', dates[4])),
              Tab(child: _buildTabLabel('Sat', dates[5])),
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
  void _showEvaluationDetailsSheet(BuildContext context, ScoreDetail mark, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    mark.subject,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    mark.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${mark.scoreReceived} / 10',
                          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  if (mark.strengths != null && mark.strengths!.isNotEmpty) ...[
                    const Text('✅ Strengths:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 6),
                    Text(mark.strengths!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  if (mark.weaknesses != null && mark.weaknesses!.isNotEmpty) ...[
                    const Text('⚠️ Areas to Improve:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 6),
                    Text(mark.weaknesses!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  if (mark.suggestedPath != null && mark.suggestedPath!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text(
                                'AI Suggested Learning Path',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mark.suggestedPath!,
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'No detailed AI learning path generated for this assessment.',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                        onTap: () => _showEvaluationDetailsSheet(context, mark, color),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(mark.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${mark.description}\nDate: ${mark.date.substring(0, 10)}'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Tap on any card to view detailed feedback & AI Path',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
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

    // Group records by subject
    final Map<String, List<AttendanceRecord>> grouped = {};
    for (var record in filtered) {
      LessonSession? lesson;
      for (var l in _lessons) {
        if (l.lessonSessionId == record.lessonSessionId) {
          lesson = l;
          break;
        }
      }
      final subjectName = lesson != null 
          ? (api.subjectMap[lesson.subjectId] ?? 'Subject ${lesson.subjectId}') 
          : 'Lesson';
      if (!grouped.containsKey(subjectName)) {
        grouped[subjectName] = [];
      }
      grouped[subjectName]!.add(record);
    }

    final sortedSubjects = grouped.keys.toList()..sort();

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedSubjects.length,
                  itemBuilder: (context, idx) {
                    final subjectName = sortedSubjects[idx];
                    final records = grouped[subjectName] ?? [];

                    // Sort records by session date in descending order (most recent first)
                    records.sort((a, b) {
                      LessonSession? lessonA;
                      for (var l in _lessons) {
                        if (l.lessonSessionId == a.lessonSessionId) {
                          lessonA = l;
                          break;
                        }
                      }
                      LessonSession? lessonB;
                      for (var l in _lessons) {
                        if (l.lessonSessionId == b.lessonSessionId) {
                          lessonB = l;
                          break;
                        }
                      }
                      final dateA = lessonA?.sessionDate ?? '';
                      final dateB = lessonB?.sessionDate ?? '';
                      return dateB.compareTo(dateA);
                    });

                    // Calculate stats
                    int present = 0;
                    int absent = 0;
                    int lateCount = 0;
                    int excused = 0;
                    for (var r in records) {
                      if (r.status == 'PRESENT') present++;
                      else if (r.status == 'ABSENT') absent++;
                      else if (r.status == 'LATE') lateCount++;
                      else if (r.status == 'EXCUSED') excused++;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x1F0A2540),
                            child: Icon(Icons.class_, color: Color(0xFF0A2540)),
                          ),
                          title: Text(
                            subjectName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2540)),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildStatChip('P: $present', Colors.green),
                                _buildStatChip('A: $absent', Colors.red),
                                _buildStatChip('L: $lateCount', Colors.orange),
                                if (excused > 0) _buildStatChip('E: $excused', Colors.blue),
                              ],
                            ),
                          ),
                          children: records.map((record) {
                            final status = record.status;
                            Color statusColor = Colors.grey;
                            IconData statusIcon = Icons.help_outline;
                            if (status == 'PRESENT') { statusColor = Colors.green; statusIcon = Icons.check_circle_outline; }
                            else if (status == 'ABSENT') { statusColor = Colors.red; statusIcon = Icons.cancel_outlined; }
                            else if (status == 'LATE') { statusColor = Colors.orange; statusIcon = Icons.watch_later_outlined; }
                            else if (status == 'EXCUSED') { statusColor = Colors.blue; statusIcon = Icons.info_outline; }

                            LessonSession? lesson;
                            for (var l in _lessons) {
                              if (l.lessonSessionId == record.lessonSessionId) {
                                lesson = l;
                                break;
                              }
                            }

                            String dateStr = 'N/A';
                            String periodAndRoom = 'Period: N/A';
                            if (lesson != null) {
                              dateStr = lesson.sessionDate.length >= 10 
                                  ? lesson.sessionDate.substring(0, 10) 
                                  : lesson.sessionDate;

                              String timeString = '';
                              for (var slot in _timetable) {
                                if (slot.period == lesson.periodNo && slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
                                  timeString = ' (${slot.startTime} - ${slot.endTime})';
                                  break;
                                }
                              }
                              periodAndRoom = 'Period ${lesson.periodNo}$timeString${lesson.room != null ? ' - Room ${lesson.room}' : ''}';
                            }

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(statusIcon, color: statusColor, size: 20),
                                title: Text(
                                  'Date: $dateStr',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Status: $status • $periodAndRoom${record.note != null && record.note!.isNotEmpty ? '\nNote: ${record.note}' : ''}',
                                  style: const TextStyle(fontSize: 12, height: 1.3),
                                ),
                                trailing: record.arrivedAt != null 
                                    ? Text(record.arrivedAt!.substring(11, 16), style: const TextStyle(fontSize: 11, color: Colors.grey))
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
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
        ? '01/12/2025 - 01/05/2026' 
        : '01/06/2026 - 06/11/2026';
        
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
