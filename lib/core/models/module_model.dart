// models/module_model.dart
import 'lesson_model.dart';

class Module {
  final int moduleId;
  final String title;
  final List<Lesson> lessons;

  Module({
    required this.moduleId,
    required this.title,
    required this.lessons,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    // Ambil daftar lessons dari JSON dan ubah jadi List<Lesson>
    var lessonList = (json['lessons'] as List)
        .map((lessonJson) => Lesson.fromJson(lessonJson))
        .toList();

    return Module(
      moduleId: json['module_id'],
      title: json['title'],
      lessons: lessonList,
    );
  }
}