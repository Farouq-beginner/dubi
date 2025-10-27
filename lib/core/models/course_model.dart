// models/course_model.dart
import 'level_model.dart';
import 'subject_model.dart';

// Model untuk Course (Kursus)
class Course {
  final int courseId;
  final String title;
  final String description;
  final Level? level;
  final Subject subject;
  final int createdByUserId;

  Course({
    required this.courseId,
    required this.title,
    required this.description,
    this.level,
    required this.subject,
    required this.createdByUserId,
  });

factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      // PASTIKAN INI BENAR:
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'] ?? '',
// [PERBAIKAN 3] Cek apakah 'level' ada sebelum di-parse
      level: json.containsKey('level') && json['level'] != null 
          ? Level.fromJson(json['level']) 
          : null,
          
      subject: Subject.fromJson(json['subject']),
      createdByUserId: json['created_by_user_id'],
    );
  }
}