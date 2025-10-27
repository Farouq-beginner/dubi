// lib/features/06_sempoa/models/sempoa_progress_model.dart
class SempoaProgress {
  final int highestLevel;
  final int highScore;
  final int highestStreak; // streak tertinggi yang pernah dicapai

  SempoaProgress({required this.highestLevel, required this.highScore, required this.highestStreak});

  factory SempoaProgress.fromJson(Map<String, dynamic> json) {
    int _getInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    // Toleransi beberapa nama kunci dari API
    final int highestLevel = _getInt(json['highest_level'] ?? json['level_highest'] ?? json['max_level'], 1);
    final int highScore = _getInt(json['high_score'] ?? json['best_score'] ?? json['score_highest'], 0);
    final int highestStreak = _getInt(
      json['highest_streak'] ?? json['high_streak'] ?? json['best_streak'] ?? json['streak_highest'],
      0,
    );

    return SempoaProgress(
      highestLevel: highestLevel,
      highScore: highScore,
      highestStreak: highestStreak,
    );
  }
}