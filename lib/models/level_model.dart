// models/level_model.dart
class Level {
  final int levelId;
  final String levelName;

  Level({required this.levelId, required this.levelName});

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelId: json['level_id'],
      levelName: json['level_name'],
    );
  }
}