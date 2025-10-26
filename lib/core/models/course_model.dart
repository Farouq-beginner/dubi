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

factory Course.fromJson(Map<String, dynamic> json) {
    // Cek jika 'subject' ada dan bukan null
    // (Penting untuk 'course->fresh()' di backend)
    final subjectData = json.containsKey('subject') && json['subject'] != null
        ? Subject.fromJson(json['subject'])
        : Subject(subjectId: json['subject_id'], subjectName: "Unknown"); // Fallback

    return Course(
      // PASTIKAN INI BENAR:
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'] ?? '',
      
      // PASTIKAN INI BENAR:
      createdByUserId: json['created_by_user_id'],
      
      subject: subjectData,
    );
  }

  get level => null;
}