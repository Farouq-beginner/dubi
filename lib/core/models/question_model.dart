// models/question_model.dart
import 'answer_model.dart';

class Question {
  final int questionId;
  final String questionText;
  final List<Answer> answers;

  Question({
    required this.questionId,
    required this.questionText,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var answerList = (json['answers'] as List)
        .map((answerJson) => Answer.fromJson(answerJson))
        .toList();

    return Question(
      questionId: json['question_id'],
      questionText: json['question_text'],
      answers: answerList,
    );
  }
}