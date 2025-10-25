// models/course_model.dart
import 'subject_model.dart';

// Model untuk Course (Kursus)
class Course {
  final int courseId;
  final String title;
  final String description;
  final Subject subject;
  final int createdByUserId;

  Course({
    required this.courseId,
    required this.title,
    required this.description,
    required this.subject,
    required this.createdByUserId,
  });

  // Factory constructor untuk mengubah JSON menjadi objek Course
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'] ?? '', // Default jika deskripsi null
      subject: Subject.fromJson(json['subject']), // Ambil data subject
      createdByUserId: json['created_by_user_id'],
    );
  }
}