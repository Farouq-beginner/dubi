// lib/core/models/level_model.dart
import 'course_model.dart'; // <-- [PERBAIKAN 1] Import Course

class Level {
  final int levelId;
  final String levelName;
  final List<Course> courses; // <-- [PERBAIKAN 2] Tambahkan list of courses

  Level({
    required this.levelId,
    required this.levelName,
    required this.courses, // <-- [PERBAIKAN 3] Tambahkan ke constructor
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    
    // Helper untuk mem-parsing list 'courses' jika ada
    List<Course> parsedCourses = [];
    if (json.containsKey('courses') && json['courses'] != null) {
      parsedCourses = (json['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    }

    return Level(
      levelId: json['level_id'],
      levelName: json['level_name'],
      courses: parsedCourses, // <-- [PERBAIKAN 4] Parse list
    );
  }
}