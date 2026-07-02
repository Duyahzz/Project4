import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class ApiService {
  // Use http://10.0.2.2:8081 for Android Emulator loopback, or http://localhost:8081 for iOS/web.
  static const String defaultBaseUrl = 'http://10.0.2.2:8081';
  String baseUrl = defaultBaseUrl;

  // Name and Email maps for translating UUIDs to user-friendly strings
  final Map<String, String> userNamesMap = {};
  final Map<String, String> userEmailsMap = {};
  final Map<int, String> subjectMap = {
    1: 'Math',
    2: 'Literature',
    3: 'English',
    4: 'Physics',
    5: 'Chemistry',
    6: 'Biology',
    7: 'History',
    8: 'Geography',
    9: 'Computer Science',
    10: 'Physical Education',
  };

  ApiService({String? customBaseUrl}) {
    if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
      baseUrl = customBaseUrl;
    }
  }

  // Helper for requests
  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
  };

  // ─── Cache loading ─────────────────────────────────────────────────────────
  Future<void> loadUserCaches() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/users')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> users = json.decode(utf8.decode(res.bodyBytes));
        for (var u in users) {
          final id = u['userId']?.toString() ?? '';
          final name = u['fullName']?.toString() ?? '';
          final email = u['email'] ?? '';
          if (id.isNotEmpty) {
            userNamesMap[id] = name;
            userEmailsMap[id] = email.toString().isNotEmpty 
                ? email.toString() 
                : '${u['username']}@estudiez.edu.vn';
          }
        }
      }

      // Fetch teachers to map teacherId -> fullName and email
      final teachersRes = await http.get(Uri.parse('$baseUrl/api/teachers')).timeout(const Duration(seconds: 3));
      if (teachersRes.statusCode == 200) {
        final List<dynamic> teachers = json.decode(utf8.decode(teachersRes.bodyBytes));
        for (var t in teachers) {
          final tId = t['teacherId']?.toString() ?? '';
          final uId = t['userId']?.toString() ?? '';
          final name = userNamesMap[uId];
          if (tId.isNotEmpty && name != null) {
            userNamesMap[tId] = name;
            final email = userEmailsMap[uId];
            if (email != null) {
              userEmailsMap[tId] = email;
            }
          }
        }
      }
    } catch (e) {
      print('[ApiService] Error loading user caches: $e');
    }
  }

  // ─── Authentication ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(),
        body: json.encode({'username': username, 'password': password}),
      );

      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        // Pre-fetch caches after successful login
        await loadUserCaches();
        return body;
      }
    } catch (e) {
      print('[ApiService] Login error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> changePasswordWithDetail(String userId, String currentPassword, String newPassword) async {
    try {
      final url = '$baseUrl/api/auth/change-password';
      final body = json.encode({
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      print('[changePassword] URL: $url');
      print('[changePassword] userId: "$userId"');
      final res = await http.post(
        Uri.parse(url),
        headers: _headers(),
        body: body,
      );
      print('[changePassword] status: ${res.statusCode}');
      print('[changePassword] response body: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      }
      // Try parse error message from server
      String errorMsg = 'Lỗi ${res.statusCode}';
      try {
        final errBody = json.decode(res.body);
        errorMsg = errBody['message'] ?? errBody['error'] ?? errorMsg;
      } catch (_) {}
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      print('[ApiService] Change password error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> changePassword(String userId, String currentPassword, String newPassword) async {
    final result = await changePasswordWithDetail(userId, currentPassword, newPassword);
    return result['success'] == true;
  }

  Future<List<ApiParent>> getParents() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/parents'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((p) => ApiParent.fromJson(p)).toList();
      }
    } catch (e) {
      print('[ApiService] getParents error: $e');
    }
    return [];
  }

  Future<List<ApiParentLink>> getParentLinks() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/parents/links'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((l) => ApiParentLink.fromJson(l)).toList();
      }
    } catch (e) {
      print('[ApiService] getParentLinks error: $e');
    }
    return [];
  }

  Future<List<ApiStudent>> getStudents() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/students'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((s) => ApiStudent.fromJson(s)).toList();
      }
    } catch (e) {
      print('[ApiService] getStudents error: $e');
    }
    return [];
  }

  // ─── Classes & Timetable ───────────────────────────────────────────────────
  Future<List<SchoolClass>> getClasses() async {
    try {
      if (userNamesMap.isEmpty) {
        await loadUserCaches();
      }
      final res = await http.get(Uri.parse('$baseUrl/api/classes'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        // Add teacher name to class models if cached
        return list.map((c) {
          final cls = SchoolClass.fromJson(c);
          final tName = userNamesMap[cls.homeroomTeacherId ?? ''];
          return SchoolClass(
            classId: cls.classId,
            name: cls.name,
            grade: cls.grade,
            year: cls.year,
            homeroomTeacherId: cls.homeroomTeacherId,
            homeroomTeacherName: tName ?? cls.homeroomTeacherId,
          );
        }).toList();
      }
    } catch (e) {
      print('[ApiService] getClasses error: $e');
    }
    return [];
  }

  Future<List<TimetableSlot>> getTimetable(int? classId) async {
    try {
      if (userNamesMap.isEmpty) {
        await loadUserCaches();
      }
      final url = classId != null 
          ? '$baseUrl/api/timetable?classId=$classId' 
          : '$baseUrl/api/timetable';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((s) => TimetableSlot.fromJson(s, subjectMap, userNamesMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getTimetable error: $e');
    }
    return [];
  }

  // ─── Resources ─────────────────────────────────────────────────────────────
  Future<List<Resource>> getResources(int? classId) async {
    try {
      if (userNamesMap.isEmpty) {
        await loadUserCaches();
      }
      final url = classId != null 
          ? '$baseUrl/api/resources?classId=$classId' 
          : '$baseUrl/api/resources';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((r) => Resource.fromJson(r, subjectMap, userNamesMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getResources error: $e');
    }
    return [];
  }

  // ─── News & Announcements ──────────────────────────────────────────────────
  Future<List<NewsItem>> getNews() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/news?status=PUBLISHED'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((n) => NewsItem.fromJson(n, userNamesMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getNews error: $e');
    }
    return [];
  }

  // ─── Notifications ─────────────────────────────────────────────────────────
  Future<List<NotificationItem>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/notifications'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((n) => NotificationItem.fromJson(n, userNamesMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getNotifications error: $e');
    }
    return [];
  }

  Future<bool> sendNotification(String title, String content, String targetType, String? targetId, String senderUserId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/notifications'),
        headers: _headers(),
        body: json.encode({
          'title': title,
          'content': content,
          'targetType': targetType, // 'CLASS', 'GRADE', 'ALL'
          'targetId': targetId,
          'senderUserId': senderUserId,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] sendNotification error: $e');
      return false;
    }
  }

  // ─── Exams / Assessments & Marks ───────────────────────────────────────────
  Future<List<Exam>> getAssessments(int? classId) async {
    try {
      final url = classId != null 
          ? '$baseUrl/api/assessments?classId=$classId' 
          : '$baseUrl/api/assessments';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((a) => Exam.fromJson(a, subjectMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getAssessments error: $e');
    }
    return [];
  }

  Future<List<ScoreDetail>> getStudentMarks(String studentId) async {
    try {
      // 1. Fetch student marks
      final res = await http.get(Uri.parse('$baseUrl/api/assessments/student/$studentId/marks'));
      if (res.statusCode == 200) {
        final List<dynamic> marksJson = json.decode(utf8.decode(res.bodyBytes));
        
        // 2. Fetch all assessments to match metadata (title, subject)
        final resAssess = await http.get(Uri.parse('$baseUrl/api/assessments'));
        final List<dynamic> assessList = resAssess.statusCode == 200 
            ? json.decode(utf8.decode(resAssess.bodyBytes)) 
            : [];
        final Map<int, dynamic> assessMap = {
          for (var a in assessList) a['assessmentId'] as int: a
        };

        return marksJson.map((m) {
          final int aId = m['assessmentId'] ?? 0;
          final assess = assessMap[aId] ?? {'title': 'Assessment $aId', 'subjectId': 1};
          return ScoreDetail.fromJson(m, assess, subjectMap, userEmailsMap);
        }).toList();
      }
    } catch (e) {
      print('[ApiService] getStudentMarks error: $e');
    }
    return [];
  }

  Future<List<ScoreDetail>> getMarksForAssessment(int assessmentId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/assessments/$assessmentId/marks'));
      if (res.statusCode == 200) {
        final List<dynamic> marks = json.decode(utf8.decode(res.bodyBytes));
        
        final resAssess = await http.get(Uri.parse('$baseUrl/api/assessments/$assessmentId'));
        final assess = resAssess.statusCode == 200 
            ? json.decode(utf8.decode(resAssess.bodyBytes)) 
            : {'title': 'Assessment', 'subjectId': 1};

        return marks.map((m) => ScoreDetail.fromJson(m, assess, subjectMap, userEmailsMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getMarksForAssessment error: $e');
    }
    return [];
  }

  Future<bool> saveStudentMark(int assessmentId, String studentId, double score) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/assessments/$assessmentId/marks'),
        headers: _headers(),
        body: json.encode({
          'assessmentId': assessmentId,
          'studentId': studentId,
          'score': score,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] saveStudentMark error: $e');
      return false;
    }
  }

  // ─── Lesson Sessions & Attendance ──────────────────────────────────────────
  Future<List<LessonSession>> getLessons(int classId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/lessons?classId=$classId'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((l) => LessonSession.fromJson(l)).toList();
      }
    } catch (e) {
      print('[ApiService] getLessons error: $e');
    }
    return [];
  }

  Future<List<AttendanceRecord>> getLessonsAttendance(int lessonSessionId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/lessons/$lessonSessionId/attendance'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((a) => AttendanceRecord.fromJson(a)).toList();
      }
    } catch (e) {
      print('[ApiService] getLessonsAttendance error: $e');
    }
    return [];
  }

  Future<List<AttendanceRecord>> getAttendanceForStudent(String studentId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/lessons/attendance/student/$studentId'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((a) => AttendanceRecord.fromJson(a)).toList();
      }
    } catch (e) {
      print('[ApiService] getAttendanceForStudent error: $e');
    }
    return [];
  }

  Future<bool> saveAttendanceRecord(int lessonSessionId, String studentId, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/lessons/$lessonSessionId/attendance'),
        headers: _headers(),
        body: json.encode({
          'lessonSessionId': lessonSessionId,
          'studentId': studentId,
          'status': status, // 'PRESENT', 'ABSENT', 'LATE', 'EXCUSED'
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] saveAttendanceRecord error: $e');
      return false;
    }
  }

  Future<bool> createLessonSession(LessonSession s) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/lessons'),
        headers: _headers(),
        body: json.encode({
          'classId': s.classId,
          'subjectId': s.subjectId,
          'teacherId': s.teacherId,
          'sessionDate': s.sessionDate,
          'periodNo': s.periodNo,
          'room': s.room,
          'topic': s.topic,
          'status': s.status,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] createLessonSession error: $e');
      return false;
    }
  }

  Future<bool> createAssessment(int classId, String title, int subjectId, int semesterId, String date) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/assessments'),
        headers: _headers(),
        body: json.encode({
          'classId': classId,
          'subjectId': subjectId,
          'semesterId': semesterId,
          'title': title,
          'assessmentDate': date,
          'status': 'SCHEDULED',
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] createAssessment error: $e');
      return false;
    }
  }

  // ─── Chat ──────────────────────────────────────────────────────────────────
  Future<List<ChatGroup>> getChatGroups() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/chat/groups'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((g) => ChatGroup.fromJson(g)).toList();
      }
    } catch (e) {
      print('[ApiService] getChatGroups error: $e');
    }
    return [];
  }

  Future<List<ChatMessage>> getChatMessages(int groupId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/chat/groups/$groupId/messages'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((m) => ChatMessage.fromJson(m, userNamesMap, userEmailsMap)).toList();
      }
    } catch (e) {
      print('[ApiService] getChatMessages error: $e');
    }
    return [];
  }

  Future<bool> sendChatMessage(int groupId, String senderUserId, String messageText) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/chat/messages'),
        headers: _headers(),
        body: json.encode({
          'chatGroupId': groupId,
          'senderUserId': senderUserId,
          'messageText': messageText,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('[ApiService] sendChatMessage error: $e');
      return false;
    }
  }

  // ─── Helpline Contacts ──────────────────────────────────────────────────────
  Future<List<Helpline>> getContacts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/contacts'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((c) => Helpline.fromJson(c)).toList();
      }
    } catch (e) {
      print('[ApiService] getContacts error: $e');
    }
    return [];
  }

  // ─── Registration Requests ─────────────────────────────────────────────────
  Future<List<RegistrationRequest>> getRegistrations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/registrations'));
      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((r) => RegistrationRequest.fromJson(r)).toList();
      }
    } catch (e) {
      print('[ApiService] getRegistrations error: $e');
    }
    return [];
  }

  Future<bool> approveRegistration(int requestId, String adminUserId) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/api/registrations/$requestId/approve'),
        headers: _headers(),
        body: json.encode({
          'reviewedBy': adminUserId,
          'reviewNotes': 'Approved via Mobile App',
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] approveRegistration error: $e');
      return false;
    }
  }

  Future<bool> rejectRegistration(int requestId, String adminUserId) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/api/registrations/$requestId/reject'),
        headers: _headers(),
        body: json.encode({
          'reviewedBy': adminUserId,
          'reviewNotes': 'Rejected via Mobile App',
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] rejectRegistration error: $e');
      return false;
    }
  }

  // ─── Student list mapping ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getStudentsForClass(int classId) async {
    try {
      // 1. Get enrollments for this class
      final resEnroll = await http.get(Uri.parse('$baseUrl/api/enrollments'));
      final List<dynamic> enrollList = resEnroll.statusCode == 200 
          ? json.decode(utf8.decode(resEnroll.bodyBytes)) 
          : [];
      final Set<String> studentIdsInClass = enrollList
          .where((e) => e['classId'] == classId && e['status'] == 'ACTIVE')
          .map((e) => e['studentId'].toString())
          .toSet();

      // 2. Get students
      final resStuds = await http.get(Uri.parse('$baseUrl/api/students'));
      final List<dynamic> studList = resStuds.statusCode == 200 
          ? json.decode(utf8.decode(resStuds.bodyBytes)) 
          : [];

      final List<Map<String, dynamic>> results = [];
      for (var s in studList) {
        final String sId = s['studentId']?.toString() ?? '';
        if (studentIdsInClass.contains(sId)) {
          results.add({
            'studentId': sId,
            'studentCode': s['studentCode'] ?? '',
            'fullName': userNamesMap[s['userId'] ?? ''] ?? sId,
            'userId': s['userId'] ?? '',
          });
        }
      }
      return results;
    } catch (e) {
      print('[ApiService] getStudentsForClass error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getEnrollments() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/enrollments'));
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      }
    } catch (e) {
      print('[ApiService] getEnrollments error: $e');
    }
    return [];
  }
}
