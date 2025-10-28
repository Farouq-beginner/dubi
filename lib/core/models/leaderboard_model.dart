// lib/features/06_sempoa/models/leaderboard_model.dart
class LeaderboardItem {
  final String userName;
  final int highestLevel;
  final int highScore;
  final int highestStreak;

  LeaderboardItem({
    required this.userName,
    required this.highestLevel,
    required this.highScore,
    required this.highestStreak,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      // Ambil dari relasi 'user'
      userName: json['user']?['full_name'] ?? json['user']?['username'] ?? 'Pengguna', 
      highestLevel: json['highest_level'] as int,
      highScore: json['high_score'] as int,
      highestStreak: json['highest_streak'] as int,
    );
  }
}