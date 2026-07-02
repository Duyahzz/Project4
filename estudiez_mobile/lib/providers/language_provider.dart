import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _locale = 'vi'; // Default to Vietnamese

  String get locale => _locale;
  bool get isVietnamese => _locale == 'vi';

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locale = prefs.getString('app_locale') ?? 'vi';
      notifyListeners();
    } catch (e) {
      print('[LanguageProvider] Load locale error: $e');
    }
  }

  Future<void> setLocale(String langCode) async {
    if (langCode != 'vi' && langCode != 'en') return;
    _locale = langCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', langCode);
    } catch (e) {
      print('[LanguageProvider] Save locale error: $e');
    }
  }

  void toggleLanguage() {
    if (_locale == 'vi') {
      setLocale('en');
    } else {
      setLocale('vi');
    }
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // ── General ──
      'app_name': 'eStudiez',
      'app_subtitle': 'Next-Gen High School Portal',
      'sign_in': 'Sign In',
      'username': 'Username',
      'password': 'Password',
      'register_now': 'Register Now',
      'no_account': "Don't have an account? ",
      'connection_settings': 'Connection settings',
      'api_settings_title': 'API Connection Settings',
      'api_settings_subtitle': 'Set the base URL of your eStudiez server:',
      'cancel': 'Cancel',
      'save': 'Save',
      'create': 'Create',
      'welcome_back': 'Welcome back,',
      'active_connection': 'Connection settings',
      'type_message': 'Type a message...',

      // ── Dashboard titles ──
      'student_dashboard': 'Student Dashboard',
      'teacher_dashboard': 'Teacher Dashboard',
      'parent_dashboard': 'Parent Dashboard',
      'admin_dashboard': 'Admin Dashboard',

      // ── Navigation tabs ──
      'home': 'Home',
      'timetable': 'Timetable',
      'marks': 'Marks',
      'attendance': 'Attendance',
      'resources': 'Resources',
      'helpline': 'Helplines',
      'chat': 'Chat',
      'profile': 'Profile',
      'logout': 'Logout',
      'roster': 'Roster',
      'assessments': 'Assessments',
      'assessments_tab': 'Assessments',
      'roster_tab': 'Roster',
      'timetable_tab': 'Timetable',
      'attendance_tab': 'Attendance',

      // ── Home tab ──
      'gpa_score': 'GPA Score',
      'attendance_rate': 'Attendance Rate',
      'recent_announcements': 'Recent Announcements',
      'my_chat_groups': 'My Chat Groups',
      'helpline_support': 'Helpline & Support',

      // ── Student sections ──
      'class_timetable': 'Class Timetable',
      'academic_performance': 'Academic Performance',
      'attendance_history': 'Attendance History',
      'study_resources': 'Study Resources',
      'semester_1': 'Semester 1',
      'semester_2': 'Semester 2',

      // ── Teacher ──
      'homeroom_portal': 'Homeroom & Subject Portal',
      'my_classes': 'My Classes',
      'no_classes': 'No classes assigned',
      'class_chat_title': 'Class Chat Channels',
      'class_chat_channels': 'Class Chat Channels',
      'no_chat': 'No chat channels active',
      'teacher_key': 'Teacher',
      'teacher': 'Teacher',
      'roll_no': 'Roll No',
      'no_roster': 'No students enrolled in this class',
      'no_timetable': 'No timetable slots allocated',
      'no_classes_today': 'No classes scheduled for today',
      'no_attendance_sessions': 'No lesson sessions registered. Tap + to add.',
      'add_lesson': 'Add Lesson Session',
      'add_lesson_session': 'Add Lesson Session',
      'topic_label': 'Topic Description',
      'topic_description': 'Topic Description',
      'period_label': 'Period No',
      'period_no': 'Period No',
      'period_short': 'Period',
      'no_assessments': 'No assessments active. Tap + to add.',
      'add_assessment_label': 'Add Assessment',
      'add_assessment': 'Add Assessment',
      'title_label': 'Title (e.g. Midterm Quiz)',
      'attendance_saved': 'Attendance recorded successfully!',
      'marks_saved': 'Marks submitted successfully!',
      'grade': 'Grade',
      'grade_button': 'Grade',
      'roster_button': 'Roster',
      'date_label': 'Date',
      'type_label': 'Type',
      'class_label': 'Class',
      'grade_label': 'Grade',
      'year_label': 'Year',

      // ── Attendance status ──
      'present': 'Present',
      'absent': 'Absent',
      'late': 'Late',
      'excused': 'Excused',

      // ── Parent ──
      'parent_portal': 'Parent Guardian Portal',
      'parent': 'Parent',
      'guardian': 'Parent / Guardian',
      'guardian_role': 'Parent / Guardian',
      'linked_students': 'Linked Students',
      'linked_students_title': 'Linked Students',
      'no_linked_students': 'No registered student is linked to your guardian account yet. Please contact school support.',
      'relationship': 'Relationship',
      'child_monitor': 'Child Monitor',
      'no_marks_child': 'No academic marks registered for child',
      'no_attendance_child': 'No attendance records found for child',

      // ── Admin ──
      'requests': 'Requests',
      'broadcast': 'Broadcast',
      'pending_registrations': 'Pending Registration Requests',
      'reject': 'Reject',
      'approve': 'Approve',
      'announcement_title': 'Announcement Title',
      'announcement_body': 'Announcement Body',
      'target_audience': 'Target Audience Type',
      'all_users': 'All Users',
      'specific_class': 'Specific Class',
      'specific_grade': 'Specific Grade',
      'broadcast_now': 'Broadcast Now',

      // ── Profile / Account ──
      'my_profile': 'My Profile',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm New Password',
      'update_password': 'Update Password',
      'submit_registration_request': 'Submit Registration Request',
      'submit_request': 'Submit Request',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'phone_number': 'Phone Number',
      'requested_role': 'Requested Role',
      'student': 'Student',
    },
    'vi': {
      // ── Chung ──
      'app_name': 'eStudiez',
      'app_subtitle': 'Cổng thông tin học tập THPT thế hệ mới',
      'sign_in': 'Đăng nhập',
      'username': 'Tài khoản',
      'password': 'Mật khẩu',
      'register_now': 'Đăng ký ngay',
      'no_account': 'Chưa có tài khoản? ',
      'connection_settings': 'Cấu hình kết nối',
      'api_settings_title': 'Cấu hình kết nối API',
      'api_settings_subtitle': 'Nhập địa chỉ URL của máy chủ eStudiez:',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'create': 'Tạo mới',
      'welcome_back': 'Chào mừng trở lại,',
      'active_connection': 'Cấu hình kết nối',
      'type_message': 'Nhập tin nhắn...',

      // ── Tiêu đề Dashboard ──
      'student_dashboard': 'Học sinh',
      'teacher_dashboard': 'Giáo viên',
      'parent_dashboard': 'Phụ huynh',
      'admin_dashboard': 'Quản trị viên',

      // ── Tab điều hướng ──
      'home': 'Trang chủ',
      'timetable': 'Lịch học',
      'marks': 'Điểm số',
      'attendance': 'Điểm danh',
      'resources': 'Tài liệu',
      'helpline': 'Trợ giúp',
      'chat': 'Trò chuyện',
      'profile': 'Hồ sơ',
      'logout': 'Đăng xuất',
      'roster': 'Sĩ số',
      'assessments': 'Bài kiểm tra',
      'assessments_tab': 'Bài kiểm tra',
      'roster_tab': 'Sĩ số',
      'timetable_tab': 'Thời khóa biểu',
      'attendance_tab': 'Điểm danh',

      // ── Tab trang chủ ──
      'gpa_score': 'Điểm trung bình (GPA)',
      'attendance_rate': 'Tỉ lệ điểm danh',
      'recent_announcements': 'Thông báo mới nhất',
      'my_chat_groups': 'Nhóm chat của tôi',
      'helpline_support': 'Hỗ trợ & Hotline',

      // ── Học sinh ──
      'class_timetable': 'Thời khóa biểu',
      'academic_performance': 'Kết quả học tập',
      'attendance_history': 'Lịch sử điểm danh',
      'study_resources': 'Tài nguyên học tập',
      'semester_1': 'Học kỳ 1',
      'semester_2': 'Học kỳ 2',

      // ── Giáo viên ──
      'homeroom_portal': 'Cổng thông tin Giáo viên',
      'my_classes': 'Lớp học của tôi',
      'no_classes': 'Chưa có lớp học nào được phân công',
      'class_chat_title': 'Kênh chat lớp học',
      'class_chat_channels': 'Kênh chat lớp học',
      'no_chat': 'Chưa có kênh chat nào hoạt động',
      'teacher_key': 'Giáo viên',
      'teacher': 'Giáo viên',
      'roll_no': 'Số thứ tự',
      'no_roster': 'Chưa có học sinh đăng ký lớp học này',
      'no_timetable': 'Chưa có lịch học nào được phân bổ',
      'no_classes_today': 'Hôm nay không có tiết học nào',
      'no_attendance_sessions': 'Chưa có buổi học nào. Nhấn + để thêm.',
      'add_lesson': 'Thêm buổi học',
      'add_lesson_session': 'Thêm buổi học',
      'topic_label': 'Chủ đề buổi học',
      'topic_description': 'Chủ đề buổi học',
      'period_label': 'Tiết học',
      'period_no': 'Tiết học',
      'period_short': 'Tiết',
      'no_assessments': 'Chưa có bài kiểm tra. Nhấn + để thêm.',
      'add_assessment_label': 'Thêm bài kiểm tra',
      'add_assessment': 'Thêm bài kiểm tra',
      'title_label': 'Tiêu đề (VD: Kiểm tra giữa kỳ)',
      'attendance_saved': 'Đã lưu điểm danh thành công!',
      'marks_saved': 'Đã nộp điểm thành công!',
      'grade': 'Nhập điểm',
      'grade_button': 'Nhập điểm',
      'roster_button': 'Điểm danh',
      'date_label': 'Ngày',
      'type_label': 'Loại',
      'class_label': 'Lớp',
      'grade_label': 'Khối',
      'year_label': 'Năm học',

      // ── Trạng thái điểm danh ──
      'present': 'Có mặt',
      'absent': 'Vắng mặt',
      'late': 'Đi trễ',
      'excused': 'Có phép',

      // ── Phụ huynh ──
      'parent_portal': 'Cổng thông tin Phụ huynh',
      'parent': 'Phụ huynh',
      'guardian': 'Phụ huynh / Người giám hộ',
      'guardian_role': 'Phụ huynh / Người giám hộ',
      'linked_students': 'Học sinh liên kết',
      'linked_students_title': 'Học sinh liên kết',
      'no_linked_students': 'Chưa có học sinh nào được liên kết với tài khoản phụ huynh này. Vui lòng liên hệ nhà trường.',
      'relationship': 'Quan hệ',
      'child_monitor': 'Theo dõi học tập',
      'no_marks_child': 'Chưa có điểm học tập nào cho con em',
      'no_attendance_child': 'Chưa có dữ liệu điểm danh nào cho con em',

      // ── Quản trị ──
      'requests': 'Yêu cầu',
      'broadcast': 'Phát thông báo',
      'pending_registrations': 'Yêu cầu đăng ký chờ duyệt',
      'reject': 'Từ chối',
      'approve': 'Phê duyệt',
      'announcement_title': 'Tiêu đề thông báo',
      'announcement_body': 'Nội dung thông báo',
      'target_audience': 'Đối tượng nhận',
      'all_users': 'Tất cả người dùng',
      'specific_class': 'Lớp cụ thể',
      'specific_grade': 'Khối lớp cụ thể',
      'broadcast_now': 'Gửi thông báo',

      // ── Hồ sơ / Tài khoản ──
      'my_profile': 'Trang cá nhân',
      'change_password': 'Đổi mật khẩu',
      'current_password': 'Mật khẩu hiện tại',
      'new_password': 'Mật khẩu mới',
      'confirm_password': 'Xác nhận mật khẩu mới',
      'update_password': 'Cập nhật mật khẩu',
      'submit_registration_request': 'Gửi yêu cầu đăng ký tài khoản',
      'submit_request': 'Gửi yêu cầu',
      'full_name': 'Họ và tên',
      'email_address': 'Địa chỉ email',
      'phone_number': 'Số điện thoại',
      'requested_role': 'Vai trò đăng ký',
      'student': 'Học sinh',
    }
  };

  String t(String key) {
    return _localizedValues[_locale]?[key] ?? key;
  }
}
