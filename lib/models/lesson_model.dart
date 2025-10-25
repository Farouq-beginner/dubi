// models/lesson_model.dart
class Lesson {
  final int lessonId;
  final String title;
  final String contentType;
  final String? contentBody; // URL Video atau teks

  Lesson({
    required this.lessonId,
    required this.title,
    required this.contentType,
    this.contentBody,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonId: json['lesson_id'],
      title: json['title'],
      contentType: json['content_type'],
      contentBody: json['content_body'],
    );
  }
}