// models/answer_model.dart
class Answer {
  final int answerId;
  final String answerText;
  final bool? isCorrect;

  Answer({required this.answerId, required this.answerText, this.isCorrect});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerId: json['answer_id'],
      answerText: json['answer_text'],
      // --- [PERBAIKAN DI SINI] ---
      // Cek dulu apakah 'is_correct' ada di JSON
      isCorrect: json.containsKey('is_correct')
          // Jika ada, cek apakah nilainya 1 (true) atau 0 (false)
          ? (json['is_correct'] == 1)
          // Jika tidak ada (misal dari API Siswa), biarkan null
          : null,
    );
  }
}