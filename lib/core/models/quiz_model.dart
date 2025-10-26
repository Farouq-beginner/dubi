// lib/core/models/quiz_model.dart
import 'question_model.dart';

class Quiz {
  final int quizId;
  final int courseId; // <-- PASTIKAN INI ADA
  final String title;
  final String description;
  final int? duration;
  final List<Question>? questions;

  Quiz({
    required this.quizId,
    required this.courseId, // <-- PASTIKAN INI ADA
    required this.title,
    required this.description,
    this.duration,
    this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quiz_id'],
      courseId: json['course_id'], // <-- PASTIKAN INI DIPARSING
      title: json['title'],
      description: json['description'] ?? '',
      duration: json['duration'],
      questions: json.containsKey('questions')
          ? (json['questions'] as List)
              .map((qJson) => Question.fromJson(qJson))
              .toList()
          : null,
    );
  }
}