class User {
  final String? userId;
  final String username;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // 'admin' | 'teacher' | 'student' | 'parent'
  final bool isActive;
  final String? subject;

  User({
    this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.subject,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Map backend roleId (1: admin, 2: teacher, 3: student, 4: parent) if role is string roleId
    String roleStr = 'student';
    final roleVal = json['role'];
    final roleId = json['roleId'];
    if (roleVal != null) {
      roleStr = roleVal.toString().toLowerCase();
    } else if (roleId != null) {
      if (roleId == 1) roleStr = 'admin';
      else if (roleId == 2) roleStr = 'teacher';
      else if (roleId == 3) roleStr = 'student';
      else if (roleId == 4) roleStr = 'parent';
    }

    return User(
      userId: json['userId'] ?? json['id'],
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: roleStr,
      isActive: json['isActive'] ?? true,
      subject: json['subject'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'isActive': isActive,
    'subject': subject,
  };
}

class SchoolClass {
  final int classId;
  final String name;
  final int grade;
  final String year;
  final String? homeroomTeacherId;
  final String? homeroomTeacherName;

  SchoolClass({
    required this.classId,
    required this.name,
    required this.grade,
    required this.year,
    this.homeroomTeacherId,
    this.homeroomTeacherName,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    int g = 10;
    final gId = json['gradeId'];
    if (gId == 1) g = 10;
    else if (gId == 2) g = 11;
    else if (gId == 3) g = 12;

    String y = '2025-2026';
    final yId = json['schoolYearId'];
    if (yId == 2) y = '2024-2025';

    return SchoolClass(
      classId: json['classId'] ?? 0,
      name: json['name'] ?? '',
      grade: g,
      year: y,
      homeroomTeacherId: json['homeroomTeacherId'],
      homeroomTeacherName: json['homeroomTeacherName'],
    );
  }
}

class TimetableSlot {
  final int id;
  final String classId;
  final String day; // 'Mon' | 'Tue' | 'Wed' | 'Thu' | 'Fri' | 'Sat'
  final int period;
  final String subject;
  final String teacher;
  final String room;
  final String system; // 'regular' | 'revision'
  final String semesterId;
  final String startTime;
  final String endTime;

  TimetableSlot({
    required this.id,
    required this.classId,
    required this.day,
    required this.period,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.system,
    required this.semesterId,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json, Map<int, String> subjectMap, Map<String, String> userNamesMap) {
    final days = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat'};
    final semesters = {1: 'S1-2025', 2: 'S2-2025'};
    
    final sId = json['subjectId'] ?? 0;
    final tId = json['teacherId'] ?? '';

    String formatTime(dynamic t) {
      if (t == null) return '';
      final str = t.toString();
      if (str.length >= 5) {
        return str.substring(0, 5);
      }
      return str;
    }

    return TimetableSlot(
      id: json['timetableSlotId'] ?? 0,
      classId: json['classId']?.toString() ?? '',
      day: days[json['dayOfWeek']] ?? 'Mon',
      period: json['periodNo'] ?? 1,
      subject: subjectMap[sId] ?? 'Subject $sId',
      teacher: userNamesMap[tId] ?? tId,
      room: json['room'] ?? '',
      system: 'regular',
      semesterId: semesters[json['semesterId']] ?? 'S1-2025',
      startTime: formatTime(json['startTime']),
      endTime: formatTime(json['endTime']),
    );
  }
}

class Resource {
  final int id;
  final String title;
  final String type; // 'video' | 'document' | 'external-link'
  final String url;
  final String subject;
  final String? classId;
  final String system;
  final String addedBy;

  Resource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.subject,
    this.classId,
    required this.system,
    required this.addedBy,
  });

  factory Resource.fromJson(Map<String, dynamic> json, Map<int, String> subjectMap, Map<String, String> userNamesMap) {
    final rTypeRaw = (json['resourceType'] ?? '').toString().toUpperCase();
    String rType = 'document';
    if (rTypeRaw == 'VIDEO') rType = 'video';
    else if (rTypeRaw == 'LINK' || rTypeRaw == 'EXTERNAL_LINK' || rTypeRaw == 'EXTERNAL-LINK') rType = 'external-link';

    final sId = json['subjectId'] ?? 0;
    final tId = json['uploadedBy'] ?? '';

    return Resource(
      id: json['resourceId'] ?? 0,
      title: json['title'] ?? '',
      type: rType,
      url: json['fileUrl'] ?? '',
      subject: subjectMap[sId] ?? 'Subject $sId',
      classId: json['classId']?.toString(),
      system: 'regular',
      addedBy: userNamesMap[tId] ?? tId,
    );
  }
}

class NewsItem {
  final int id;
  final String title;
  final String body;
  final String date;
  final String author;
  final String category;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.author,
    required this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json, Map<String, String> userNamesMap) {
    final tId = json['authorUserId'] ?? '';
    final rawDate = json['publishedAt'] ?? json['createdAt'] ?? '';
    return NewsItem(
      id: json['newsPostId'] ?? 0,
      title: json['title'] ?? '',
      body: json['content'] ?? '',
      date: rawDate.toString().length >= 10 ? rawDate.toString().substring(0, 10) : rawDate,
      author: userNamesMap[tId] ?? tId,
      category: json['category'] ?? 'GENERAL',
    );
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String date;
  final String audience; // 'class' | 'grade' | 'all'
  final String? target;
  final String sender;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.audience,
    this.target,
    required this.sender,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json, Map<String, String> userNamesMap) {
    final tId = json['senderUserId'] ?? '';
    final rawDate = json['createdAt'] ?? '';
    return NotificationItem(
      id: json['notificationId'] ?? 0,
      title: json['title'] ?? '',
      body: json['content'] ?? '',
      date: rawDate.toString().length >= 10 ? rawDate.toString().substring(0, 10) : rawDate,
      audience: (json['targetType'] ?? 'class').toString().toLowerCase(),
      target: json['targetId']?.toString(),
      sender: userNamesMap[tId] ?? tId,
    );
  }
}

class Exam {
  final int id;
  final String semesterId;
  final String subject;
  final String name;
  final String date;
  final bool completed;

  Exam({
    required this.id,
    required this.semesterId,
    required this.subject,
    required this.name,
    required this.date,
    required this.completed,
  });

  factory Exam.fromJson(Map<String, dynamic> json, Map<int, String> subjectMap) {
    final semesters = {1: 'S1-2025', 2: 'S2-2025'};
    final sId = json['subjectId'] ?? 0;
    return Exam(
      id: json['assessmentId'] ?? 0,
      semesterId: semesters[json['semesterId']] ?? 'S1-2025',
      subject: subjectMap[sId] ?? 'Subject $sId',
      name: json['title'] ?? '',
      date: json['assessmentDate'] ?? '',
      completed: json['status'] == 'COMPLETED',
    );
  }
}

class ScoreDetail {
  final int id;
  final String studentEmail;
  final String classId;
  final String subject;
  final String testId;
  final String description;
  final String date;
  final double scoreReceived;
  final int semesterId;

  ScoreDetail({
    required this.id,
    required this.studentEmail,
    required this.classId,
    required this.subject,
    required this.testId,
    required this.description,
    required this.date,
    required this.scoreReceived,
    this.semesterId = 1,
  });

  factory ScoreDetail.fromJson(Map<String, dynamic> json, Map<String, dynamic> assessmentJson, Map<int, String> subjectMap, Map<String, String> userEmailsMap) {
    final sId = assessmentJson['subjectId'] ?? 0;
    final studId = json['studentId'] ?? '';
    return ScoreDetail(
      id: json['studentMarkId'] ?? 0,
      studentEmail: userEmailsMap[studId] ?? studId,
      classId: (assessmentJson['classId'] ?? '').toString(),
      subject: subjectMap[sId] ?? 'Subject $sId',
      testId: (json['assessmentId'] ?? '').toString(),
      description: assessmentJson['title'] ?? '',
      date: assessmentJson['assessmentDate'] ?? '',
      scoreReceived: (json['score'] ?? 0.0).toDouble(),
      semesterId: assessmentJson['semesterId'] ?? 1,
    );
  }
}

class ChatGroup {
  final String id;
  final String name;
  final String classId;
  final String year;
  final String type; // 'student-teacher' | 'parent-teacher' | 'teacher-only'

  ChatGroup({
    required this.id,
    required this.name,
    required this.classId,
    required this.year,
    required this.type,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    final rawType = (json['groupType'] ?? 'student-teacher').toString().toLowerCase().replaceAll('_', '-');
    final years = {1: '2025-2026', 2: '2024-2025'};
    return ChatGroup(
      id: (json['chatGroupId'] ?? '').toString(),
      name: json['name'] ?? '',
      classId: (json['classId'] ?? '').toString(),
      year: years[json['schoolYearId']] ?? '2025-2026',
      type: rawType,
    );
  }
}

class ChatMessage {
  final int id;
  final String groupId;
  final String senderEmail;
  final String senderName;
  final String body;
  final String sentAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderEmail,
    required this.senderName,
    required this.body,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, Map<String, String> userNamesMap, Map<String, String> userEmailsMap) {
    final sId = json['senderUserId'] ?? '';
    return ChatMessage(
      id: json['chatMessageId'] ?? 0,
      groupId: (json['chatGroupId'] ?? '').toString(),
      senderEmail: userEmailsMap[sId] ?? sId,
      senderName: userNamesMap[sId] ?? sId,
      body: json['messageText'] ?? '',
      sentAt: json['createdAt'] ?? '',
    );
  }
}

class RegistrationRequest {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // 'student' | 'teacher' | 'parent'
  final String status; // 'pending' | 'approved' | 'rejected'
  final String submittedAt;

  RegistrationRequest({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    required this.submittedAt,
  });

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ?? '';
    return RegistrationRequest(
      id: json['requestId'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      role: json['roleRequested'] ?? 'student',
      status: (json['status'] ?? 'PENDING').toString().toLowerCase(),
      submittedAt: rawDate.toString().length >= 16 ? rawDate.toString().substring(0, 16) : rawDate,
    );
  }
}

class LessonSession {
  final int lessonSessionId;
  final int? timetableSlotId;
  final int classId;
  final int subjectId;
  final String teacherId;
  final String sessionDate;
  final int periodNo;
  final String? room;
  final String? topic;
  final String status;

  LessonSession({
    required this.lessonSessionId,
    this.timetableSlotId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.sessionDate,
    required this.periodNo,
    this.room,
    this.topic,
    required this.status,
  });

  factory LessonSession.fromJson(Map<String, dynamic> json) {
    return LessonSession(
      lessonSessionId: json['lessonSessionId'] ?? 0,
      timetableSlotId: json['timetableSlotId'],
      classId: json['classId'] ?? 0,
      subjectId: json['subjectId'] ?? 0,
      teacherId: json['teacherId'] ?? '',
      sessionDate: json['sessionDate'] ?? '',
      periodNo: json['periodNo'] ?? 1,
      room: json['room'],
      topic: json['topic'],
      status: json['status'] ?? 'SCHEDULED',
    );
  }
}

class AttendanceRecord {
  final int attendanceRecordId;
  final int lessonSessionId;
  final String studentId;
  final String status; // 'PRESENT' | 'ABSENT' | 'LATE' | 'EXCUSED'
  final String? arrivedAt;
  final String? note;

  AttendanceRecord({
    required this.attendanceRecordId,
    required this.lessonSessionId,
    required this.studentId,
    required this.status,
    this.arrivedAt,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceRecordId: json['attendanceRecordId'] ?? 0,
      lessonSessionId: json['lessonSessionId'] ?? 0,
      studentId: json['studentId'] ?? '',
      status: json['status'] ?? 'PRESENT',
      arrivedAt: json['arrivedAt'],
      note: json['note'],
    );
  }
}

class Helpline {
  final String label;
  final String phone;

  Helpline({
    required this.label,
    required this.phone,
  });

  factory Helpline.fromJson(Map<String, dynamic> json) {
    return Helpline(
      label: json['name'] ?? '',
      phone: json['phone'] ?? json['email'] ?? '',
    );
  }
}

class ApiParent {
  final String? parentId;
  final String? userId;
  final String? occupation;
  final String? address;

  ApiParent({
    this.parentId,
    this.userId,
    this.occupation,
    this.address,
  });

  factory ApiParent.fromJson(Map<String, dynamic> json) {
    return ApiParent(
      parentId: json['parentId']?.toString(),
      userId: json['userId']?.toString(),
      occupation: json['occupation']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class ApiParentLinkId {
  final String studentId;
  final String parentId;

  ApiParentLinkId({
    required this.studentId,
    required this.parentId,
  });

  factory ApiParentLinkId.fromJson(Map<String, dynamic> json) {
    return ApiParentLinkId(
      studentId: json['studentId']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? '',
    );
  }
}

class ApiParentLink {
  final ApiParentLinkId id;
  final String? relationship;
  final bool? isPrimaryContact;

  ApiParentLink({
    required this.id,
    this.relationship,
    this.isPrimaryContact,
  });

  factory ApiParentLink.fromJson(Map<String, dynamic> json) {
    return ApiParentLink(
      id: ApiParentLinkId.fromJson(json['id'] ?? {}),
      relationship: json['relationship']?.toString(),
      isPrimaryContact: json['isPrimaryContact'] as bool?,
    );
  }
}

class ApiStudent {
  final String studentId;
  final String? studentCode;
  final String? userId;
  final String? address;
  final String? status;

  ApiStudent({
    required this.studentId,
    this.studentCode,
    this.userId,
    this.address,
    this.status,
  });

  factory ApiStudent.fromJson(Map<String, dynamic> json) {
    return ApiStudent(
      studentId: json['studentId']?.toString() ?? '',
      studentCode: json['studentCode']?.toString(),
      userId: json['userId']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
