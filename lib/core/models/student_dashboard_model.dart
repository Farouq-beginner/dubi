// lib/core/models/student_dashboard_model.dart

// 1. Model untuk Statistik Keseluruhan
class DashboardStatistics {
  final int coursesCompleted;
  final int quizzesPassed;
  final double averageScore;

  DashboardStatistics({
    required this.coursesCompleted,
    required this.quizzesPassed,
    required this.averageScore,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      coursesCompleted: json['courses_completed'] as int,
      quizzesPassed: json['quizzes_passed'] as int,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// 2. Model untuk Progres Kursus (Sama seperti CourseProgressItem)
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

// 3. Model untuk Riwayat Kuis Terbaru
class RecentQuizAttempt {
  final int attemptId;
  final String quizTitle;
  final double score;
  final String completedAt;

  RecentQuizAttempt({
    required this.attemptId,
    required this.quizTitle,
    required this.score,
    required this.completedAt,
  });

  factory RecentQuizAttempt.fromJson(Map<String, dynamic> json) {
    return RecentQuizAttempt(
      attemptId: json['attempt_id'],
      quizTitle: json['quiz'] != null ? json['quiz']['title'] : 'Kuis Dihapus',
      score: double.parse(json['score'].toString()), // Konversi desimal/string
      completedAt: json['completed_at'] ?? 'N/A',
    );
  }
}

// 4. Model Gabungan (Utama)
class StudentDashboard {
  final String userName;
  final DashboardStatistics statistics;
  final List<CourseProgressItem> courseProgress;
  final List<RecentQuizAttempt> recentQuizHistory;

  StudentDashboard({
    required this.userName,
    required this.statistics,
    required this.courseProgress,
    required this.recentQuizHistory,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      userName: json['user_name'],
      statistics: DashboardStatistics.fromJson(json['statistics']),
      courseProgress: (json['course_progress'] as List).map((i) => CourseProgressItem.fromJson(i)).toList(),
      recentQuizHistory: (json['recent_quiz_history'] as List).map((i) => RecentQuizAttempt.fromJson(i)).toList(),
    );
  }
}