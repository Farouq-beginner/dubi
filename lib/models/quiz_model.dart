// models/quiz_model.dart
import 'question_model.dart';

class Quiz {
  final int quizId;
  final String title;
  final String description;
  final List<Question>? questions; // Nullable, karena kadang kita cuma butuh list

  Quiz({
    required this.quizId,
    required this.title,
    required this.description,
    this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quiz_id'],
      title: json['title'],
      description: json['description'] ?? '',
      // Cek jika 'questions' ada di JSON, baru di-parse
      questions: json.containsKey('questions')
          ? (json['questions'] as List)
              .map((qJson) => Question.fromJson(qJson))
              .toList()
          : null,
    );
  }
}