import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models.dart';
import '../student/student_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_list_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _children = [];
  List<ChatGroup> _chatGroups = [];
  List<NotificationItem> _notifications = [];
  Set<int> _childClassIds = {};

  DateTime? _lastReadNotificationsTime;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadLastReadNotifsTime();
    _fetchChildren();
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
      await _silentFetchChildren();
    });
  }

  Future<void> _silentFetchChildren() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;
    final parentUserId = auth.currentUser?.userId ?? '';

    try {
      final parentsRes = await api.getParents();
      String parentId = '';
      for (var p in parentsRes) {
        if (p.userId == parentUserId) {
          parentId = p.parentId ?? '';
          break;
        }
      }

      final linksRes = await api.getParentLinks();
      final childLinks = linksRes.where((l) => l.id.parentId == parentId).toList();

      final studentsRes = await api.getStudents();
      final enrollments = await api.getEnrollments();
      final Set<int> childClassIds = {};

      final List<Map<String, dynamic>> childList = [];
      for (var link in childLinks) {
        final studentId = link.id.studentId;
        final studentObj = studentsRes.firstWhere(
          (s) => s.studentId == studentId,
          orElse: () => ApiStudent(studentId: studentId),
        );

        int? resolvedClassId;
        for (var e in enrollments) {
          if (e['studentId']?.toString() == studentId && e['status'] == 'ACTIVE') {
            resolvedClassId = e['classId'] as int?;
            if (resolvedClassId != null) {
              childClassIds.add(resolvedClassId);
            }
            break;
          }
        }

        final String uId = studentObj.userId ?? '';
        final String fullName = api.userNamesMap[uId] ?? 'Student $studentId';
        final String studentCode = studentObj.studentCode ?? '';

        childList.add({
          'studentId': studentId,
          'fullName': fullName,
          'studentCode': studentCode,
          'relationship': link.relationship ?? 'Child',
          'classId': resolvedClassId,
        });
      }

      final allChats = await api.getChatGroups();
      final filteredChats = allChats.where((g) => 
        g.type == 'parent-teacher' && 
        childClassIds.contains(int.tryParse(g.classId) ?? -1)
      ).toList();

      final allNotifs = await api.getNotifications();
      final parentEmail = auth.currentUser?.email;
      final filteredNotifs = allNotifs.where((n) {
        final aud = n.audience.toLowerCase();
        return aud == 'all' || 
               (aud == 'parent' && n.target?.toLowerCase() == parentEmail?.toLowerCase()) ||
               (aud == 'class' && childClassIds.contains(int.tryParse(n.target ?? '')));
      }).toList();
      filteredNotifs.sort((a, b) => b.id.compareTo(a.id));

      if (mounted) {
        setState(() {
          _children = childList;
          _chatGroups = filteredChats;
          _notifications = filteredNotifs;
          _childClassIds = childClassIds;
        });
      }
    } catch (e) {
      debugPrint('Error silently fetching parent children: $e');
    }
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
          _chatGroups = [];
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Get parent-student links to find studentIds linked to parentId
      final linksRes = await api.getParentLinks();
      final childLinks = linksRes.where((l) => l.id.parentId == parentId).toList();

      // 3. Get students details to match studentIds
      final studentsRes = await api.getStudents();
      
      // Get enrollments to find classId for each child
      final enrollments = await api.getEnrollments();
      final Set<int> childClassIds = {};

      final List<Map<String, dynamic>> childList = [];
      for (var link in childLinks) {
        final studentId = link.id.studentId;
        final studentObj = studentsRes.firstWhere(
          (s) => s.studentId == studentId,
          orElse: () => ApiStudent(studentId: studentId),
        );

        int? resolvedClassId;
        for (var e in enrollments) {
          if (e['studentId']?.toString() == studentId && e['status'] == 'ACTIVE') {
            resolvedClassId = e['classId'] as int?;
            if (resolvedClassId != null) {
              childClassIds.add(resolvedClassId);
            }
            break;
          }
        }

        final String uId = studentObj.userId ?? '';
        final String fullName = api.userNamesMap[uId] ?? 'Student $studentId';
        final String studentCode = studentObj.studentCode ?? '';

        childList.add({
          'studentId': studentId,
          'fullName': fullName,
          'studentCode': studentCode,
          'relationship': link.relationship ?? 'Child',
          'classId': resolvedClassId,
        });
      }

      // Fetch all chat groups and filter parent-teacher groups matching child classIds
      final allChats = await api.getChatGroups();
      final filteredChats = allChats.where((g) => 
        g.type == 'parent-teacher' && 
        childClassIds.contains(int.tryParse(g.classId) ?? -1)
      ).toList();

      // Fetch notifications
      final allNotifs = await api.getNotifications();
      final parentEmail = auth.currentUser?.email;
      final filteredNotifs = allNotifs.where((n) {
        final aud = n.audience.toLowerCase();
        return aud == 'all' || 
               (aud == 'parent' && n.target?.toLowerCase() == parentEmail?.toLowerCase()) ||
               (aud == 'class' && childClassIds.contains(int.tryParse(n.target ?? '')));
      }).toList();
      filteredNotifs.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        _children = childList;
        _chatGroups = filteredChats;
        _notifications = filteredNotifs;
        _childClassIds = childClassIds;
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
          Stack(
            alignment: Alignment.center,
            children: [

              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () async {
                  try {
                    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                    final rawNotifs = await api.getNotifications();
                    final parentEmail = Provider.of<AuthProvider>(context, listen: false).currentUser?.email;
                    final filteredNotifs = rawNotifs.where((n) {
                      final aud = n.audience.toLowerCase();
                      return aud == 'all' || 
                             (aud == 'parent' && n.target?.toLowerCase() == parentEmail?.toLowerCase()) ||
                             (aud == 'class' && _childClassIds.contains(int.tryParse(n.target ?? '')));
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

                  if (result != null && result is Map) {
                    final int? tabIndex = result['tabIndex'] as int?;
                    final String? body = result['body'] as String?;
                    if (tabIndex != null && tabIndex >= 0) {
                      // Map tabIndex: 2 (Marks) -> index 1, 3 (Attendance) -> index 2
                      int targetTab = 0;
                      if (tabIndex == 2) targetTab = 1;
                      else if (tabIndex == 3) targetTab = 2;

                      // Parse child name from body: "Con của bạn (Bui Duc Minh)..."
                      String studentName = "";
                      if (body != null) {
                        final match = RegExp(r"\(([^)]+)\)").firstMatch(body);
                        if (match != null) {
                          studentName = match.group(1) ?? "";
                        }
                      }

                      // Find matching child
                      Map<String, dynamic>? targetChild;
                      if (studentName.isNotEmpty) {
                        for (var child in _children) {
                          if (child['fullName'].toString().toLowerCase() == studentName.toLowerCase()) {
                            targetChild = child;
                            break;
                          }
                        }
                      }
                      // Default to first child if not found
                      if (targetChild == null && _children.isNotEmpty) {
                        targetChild = _children[0];
                      }

                      if (targetChild != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildMonitorScreen(
                              studentId: targetChild!['studentId'].toString(),
                              fullName: targetChild!['fullName'].toString(),
                              initialIndex: targetTab,
                            ),
                          ),
                        );
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
                      borderRadius: BorderRadius.circular(6),
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
          : SingleChildScrollView(
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
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 24),
                  Text(
                    lang.t('my_chat_groups'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                  ),
                  const SizedBox(height: 8),
                  _chatGroups.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                lang.t('no_chat'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
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
                                      builder: (context) => ChatScreen(
                                        groupId: int.parse(group.id),
                                        groupName: group.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                  Text(
                    lang.isVietnamese ? 'Thông báo' : 'Notifications',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                  ),
                  const SizedBox(height: 8),
                  _notifications.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                lang.isVietnamese ? 'Không có thông báo mới' : 'No new notifications',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
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
  final int initialIndex;
  const ChildMonitorScreen({Key? key, required this.studentId, required this.fullName, this.initialIndex = 0}) : super(key: key);

  @override
  State<ChildMonitorScreen> createState() => _ChildMonitorScreenState();
}

class _ChildMonitorScreenState extends State<ChildMonitorScreen> {
  bool _isLoading = true;
  List<TimetableSlot> _timetable = [];
  List<ScoreDetail> _marks = [];
  List<AttendanceRecord> _attendance = [];
  List<LessonSession> _lessons = [];

  int _selectedSemester = 1;
  int _selectedTimetableSemester = 1;
  Timer? _childDataTimer;

  @override
  void initState() {
    super.initState();
    _fetchChildData();
    _startChildDataTimer();
  }

  @override
  void dispose() {
    _childDataTimer?.cancel();
    super.dispose();
  }

  void _startChildDataTimer() {
    _childDataTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _pollChildData();
    });
  }

  Future<void> _pollChildData() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    try {
      int? resolvedClassId;
      try {
        final enrollments = await api.getEnrollments();
        for (var e in enrollments) {
          if (e['studentId']?.toString() == widget.studentId && e['status'] == 'ACTIVE') {
            resolvedClassId = e['classId'] as int?;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error resolving child classId: $e');
      }

      final results = await Future.wait([
        api.getTimetable(resolvedClassId),
        api.getStudentMarks(widget.studentId),
        api.getAttendanceForStudent(widget.studentId),
        api.getLessons(resolvedClassId ?? 0),
      ]);

      if (mounted) {
        setState(() {
          _timetable = results[0] as List<TimetableSlot>;
          _marks = results[1] as List<ScoreDetail>;
          _attendance = results[2] as List<AttendanceRecord>;
          _lessons = results[3] as List<LessonSession>;
        });
      }
    } catch (e) {
      debugPrint('Error polling child details: $e');
    }
  }

  Future<void> _fetchChildData() async {
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    setState(() => _isLoading = true);

    try {
      int? resolvedClassId;
      try {
        final enrollments = await api.getEnrollments();
        for (var e in enrollments) {
          if (e['studentId']?.toString() == widget.studentId && e['status'] == 'ACTIVE') {
            resolvedClassId = e['classId'] as int?;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error resolving child classId: $e');
      }

      final results = await Future.wait([
        api.getTimetable(resolvedClassId),
        api.getStudentMarks(widget.studentId),
        api.getAttendanceForStudent(widget.studentId),
        api.getLessons(resolvedClassId ?? 0),
      ]);

      setState(() {
        _timetable = results[0] as List<TimetableSlot>;
        _marks = results[1] as List<ScoreDetail>;
        _attendance = results[2] as List<AttendanceRecord>;
        _lessons = results[3] as List<LessonSession>;
        if (_marks.isNotEmpty) {
          final sorted = List<ScoreDetail>.from(_marks);
          sorted.sort((a, b) => b.date.compareTo(a.date));
          _selectedSemester = sorted.first.semesterId;
        }
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
      initialIndex: widget.initialIndex,
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

  Widget _buildTimetableTab(LanguageProvider lang) {
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

    final dayLabels = lang.isVietnamese
        ? {'Mon': 'T.2', 'Tue': 'T.3', 'Wed': 'T.4', 'Thu': 'T.5', 'Fri': 'T.6', 'Sat': 'T.7'}
        : {'Mon': 'Mon', 'Tue': 'Tue', 'Wed': 'Wed', 'Thu': 'Thu', 'Fri': 'Fri', 'Sat': 'Sat'};

    final dates = _getTimetableDates();
    final today = DateTime.now().weekday; // Mon=1, ..., Sun=7
    final initialIndex = (today >= 1 && today <= 6) ? (today - 1) : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildTimetableSemesterSelector(lang),
        ),
        Expanded(
          child: DefaultTabController(
            length: 6,
            initialIndex: initialIndex,
            child: Scaffold(
              appBar: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFFED7D31),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFED7D31),
                tabs: [
                  Tab(child: _buildTabLabel(dayLabels['Mon'] ?? 'Mon', dates[0])),
                  Tab(child: _buildTabLabel(dayLabels['Tue'] ?? 'Tue', dates[1])),
                  Tab(child: _buildTabLabel(dayLabels['Wed'] ?? 'Wed', dates[2])),
                  Tab(child: _buildTabLabel(dayLabels['Thu'] ?? 'Thu', dates[3])),
                  Tab(child: _buildTabLabel(dayLabels['Fri'] ?? 'Fri', dates[4])),
                  Tab(child: _buildTabLabel(dayLabels['Sat'] ?? 'Sat', dates[5])),
                ],
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
          ),
        ),
      ],
    );
  }

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

  Widget _buildMarksTab(LanguageProvider lang) {
    final filtered = _marks.where((m) => m.semesterId == _selectedSemester).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSemesterSelector(lang),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(lang.t('no_marks_child')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final mark = filtered[idx];
                    final score = mark.scoreReceived;
                    final color = score >= 8.0 ? Colors.green : score >= 5.0 ? Colors.orange : Colors.red;

                    return Card(
                      child: ListTile(
                        onTap: () => _showEvaluationDetailsSheet(context, mark, color),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Text(score.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(mark.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${mark.description}\n${lang.t('date_label')}: ${mark.date.substring(0, 10)}'),
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

  Widget _buildAttendanceTab(LanguageProvider lang) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = auth.apiService;

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
              ? Center(child: Text(lang.t('no_attendance_child')))
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
}
