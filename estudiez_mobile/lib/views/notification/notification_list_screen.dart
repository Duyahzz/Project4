import 'package:flutter/material.dart';
import '../../models.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';

Map<String, String> localizeNotification(String title, String body, bool isVietnamese) {
  String localizedTitle = title;
  String localizedBody = body;

  final titleLower = title.toLowerCase();
  
  if (titleLower.contains('điểm danh') || titleLower.contains('attendance')) {
    // Attendance notification
    if (titleLower.contains('con') || body.toLowerCase().contains('con của bạn')) {
      // Parent attendance
      localizedTitle = isVietnamese ? 'Cập nhật điểm danh của con' : 'Child\'s Attendance Updated';
      
      // Body pattern: "Con của bạn (fullName) đã được điểm danh: (status) cho môn (subject) ngày (date)"
      final reg = RegExp(r"Con của bạn \(([^)]+)\) đã được điểm danh: (.+?) cho môn (.+?) ngày ([0-9-]+)");
      final match = reg.firstMatch(body);
      if (match != null) {
        final childName = match.group(1);
        final statusVi = match.group(2);
        final subject = match.group(3);
        final dateStr = match.group(4);
        
        String statusEn = statusVi ?? "";
        if (statusVi == "Có mặt") statusEn = "Present";
        else if (statusVi == "Vắng mặt") statusEn = "Absent";
        else if (statusVi == "Đi muộn") statusEn = "Late";
        else if (statusVi == "Nghỉ có phép") statusEn = "Excused";

        if (isVietnamese) {
          localizedBody = "Con của bạn ($childName) đã được điểm danh: $statusVi cho môn $subject ngày $dateStr";
        } else {
          localizedBody = "Your child ($childName) has been marked: $statusEn for $subject on $dateStr";
        }
      }
    } else {
      // Student attendance
      localizedTitle = isVietnamese ? 'Cập nhật điểm danh' : 'Attendance Updated';
      
      // Body pattern: "Bạn đã được điểm danh: (status) cho môn (subject) ngày (date)"
      final reg = RegExp(r"Bạn đã được điểm danh: (.+?) cho môn (.+?) ngày ([0-9-]+)");
      final match = reg.firstMatch(body);
      if (match != null) {
        final statusVi = match.group(1);
        final subject = match.group(2);
        final dateStr = match.group(3);

        String statusEn = statusVi ?? "";
        if (statusVi == "Có mặt") statusEn = "Present";
        else if (statusVi == "Vắng mặt") statusEn = "Absent";
        else if (statusVi == "Đi muộn") statusEn = "Late";
        else if (statusVi == "Nghỉ có phép") statusEn = "Excused";

        if (isVietnamese) {
          localizedBody = "Bạn đã được điểm danh: $statusVi cho môn $subject ngày $dateStr";
        } else {
          localizedBody = "You have been marked: $statusEn for $subject on $dateStr";
        }
      }
    }
  } else if (titleLower.contains('điểm số') || titleLower.contains('score') || 
             body.toLowerCase().contains('điểm số mới') || body.toLowerCase().contains('score')) {
    // Score notification
    if (titleLower.contains('con') || body.toLowerCase().contains('con của bạn')) {
      // Parent score
      localizedTitle = isVietnamese ? 'Điểm số mới của con' : 'Child\'s New Score';
      
      // Body pattern: "Con của bạn (fullName) có điểm số mới môn (subject) (Bài kiểm tra: (test)): (score) điểm."
      final reg = RegExp(r"Con của bạn \(([^)]+)\) có điểm số mới môn (.+?) \(Bài kiểm tra: (.+?)\): ([0-9.]+) điểm\.");
      final match = reg.firstMatch(body);
      if (match != null) {
        final childName = match.group(1);
        final subject = match.group(2);
        final testName = match.group(3);
        final score = match.group(4);

        if (isVietnamese) {
          localizedBody = "Con của bạn ($childName) có điểm số mới môn $subject (Bài kiểm tra: $testName): $score điểm.";
        } else {
          localizedBody = "Your child ($childName) has a new score in $subject (Assessment: $testName): $score points.";
        }
      }
    } else {
      // Student score
      localizedTitle = isVietnamese ? 'Điểm số mới' : 'New Score';
      
      // Body pattern: "Bạn có điểm số mới môn (subject) (Bài kiểm tra: (test)): (score) điểm."
      final reg = RegExp(r"Bạn có điểm số mới môn (.+?) \(Bài kiểm tra: (.+?)\): ([0-9.]+) điểm\.");
      final match = reg.firstMatch(body);
      if (match != null) {
        final subject = match.group(1);
        final testName = match.group(2);
        final score = match.group(3);

        if (isVietnamese) {
          localizedBody = "Bạn có điểm số mới môn $subject (Bài kiểm tra: $testName): $score điểm.";
        } else {
          localizedBody = "You have a new score in $subject (Assessment: $testName): $score points.";
        }
      }
    }
  }

  return {
    'title': localizedTitle,
    'body': localizedBody,
  };
}

class NotificationListScreen extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationListScreen({Key? key, required this.notifications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.isVietnamese ? 'Thông báo' : 'Notifications'),
        backgroundColor: const Color(0xFF0A2540),
        foregroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                lang.isVietnamese ? 'Không có thông báo nào' : 'No notifications',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, idx) {
                final item = notifications[idx];
                
                // Localize title and body dynamically
                final localized = localizeNotification(item.title, item.body, lang.isVietnamese);
                final dispTitle = localized['title'] ?? item.title;
                final dispBody = localized['body'] ?? item.body;

                // Determine icon and color based on category
                IconData icon = Icons.notifications;
                Color color = const Color(0xFF0A2540);
                
                if (item.category == 'MARK') {
                  icon = Icons.grade_outlined;
                  color = const Color(0xFFED7D31);
                } else if (item.category == 'ATTENDANCE') {
                  icon = Icons.check_circle_outline;
                  color = Colors.green;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      dispTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '$dispBody\n${item.date}',
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      int tabIndex = -1;
                      if (item.category == 'MARK') {
                        tabIndex = 2;
                      } else if (item.category == 'ATTENDANCE') {
                        tabIndex = 3;
                      }
                      
                      Navigator.pop(context, {
                        'tabIndex': tabIndex,
                        'body': item.body, // Return raw body so parent dashboard can parse name correctly
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
