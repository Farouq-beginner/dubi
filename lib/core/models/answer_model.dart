// models/answer_model.dart
class Answer {
  final int answerId;
  final String answerText;

  Answer({required this.answerId, required this.answerText});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerId: json['answer_id'],
      answerText: json['answer_text'],
    );
  }
}