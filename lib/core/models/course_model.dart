// models/course_model.dart
import 'level_model.dart';
import 'subject_model.dart';

// Model untuk Course (Kursus)
class Course {
  final int courseId;
  final String title;
  final String description;
  final Level level;
  final Subject subject;
  final int createdByUserId;

  Course({
    required this.courseId,
    required this.title,
    required this.description,
    required this.level,
    required this.subject,
    required this.createdByUserId,
  });

factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      // PASTIKAN INI BENAR:
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'] ?? '',
      level: Level.fromJson(json['level']),
      subject: Subject.fromJson(json['subject']),
      // PASTIKAN INI BENAR:
      createdByUserId: json['created_by_user_id'],
    );
  }
}