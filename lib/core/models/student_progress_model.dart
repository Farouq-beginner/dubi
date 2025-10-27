// lib/core/models/student_progress_model.dart

// Model untuk riwayat skor kuis
class QuizHistoryItem {
  final int quizId;
  final String quizTitle;
  final double highScore;

  QuizHistoryItem({required this.quizId, required this.quizTitle, required this.highScore});

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      quizId: json['quiz_id'],
      quizTitle: json['quiz'] != null ? json['quiz']['title'] : 'Kuis Dihapus',
      highScore: double.parse(json['high_score'].toString()), // Konversi desimal/string
    );
  }
}

// Model untuk progres materi per kursus
class CourseProgressItem {
  final int courseId;
  final String courseTitle;
  final int completedLessons;
  final int totalLessons;
  final int progressPercentage;

  CourseProgressItem({
    required this.courseId,
    required this.courseTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercentage,
  });

  factory CourseProgressItem.fromJson(Map<String, dynamic> json) {
    return CourseProgressItem(
      courseId: json['course_id'],
      courseTitle: json['course_title'],
      completedLessons: json['completed_lessons'],
      totalLessons: json['total_lessons'],
      progressPercentage: (json['progress_percentage'] as num).toInt(),
    );
  }
}

// Model gabungan untuk dashboard
class StudentProgress {
  final String userName;
  final List<QuizHistoryItem> quizHistory;
  final List<CourseProgressItem> courseProgress;

  StudentProgress({
    required this.userName,
    required this.quizHistory,
    required this.courseProgress,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      userName: json['user_name'],
      quizHistory: (json['quiz_history'] as List).map((i) => QuizHistoryItem.fromJson(i)).toList(),
      courseProgress: (json['course_progress'] as List).map((i) => CourseProgressItem.fromJson(i)).toList(),
    );
  }
}