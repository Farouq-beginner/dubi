// models/course_detail_model.dart
import 'module_model.dart';
import 'quiz_model.dart';

class CourseDetail {
  final List<Module> modules;
  final List<Quiz> quizzes;

  CourseDetail({required this.modules, required this.quizzes});

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    var moduleList = (json['modules'] as List)
        .map((mJson) => Module.fromJson(mJson))
        .toList();
    
    var quizList = (json['quizzes'] as List)
        .map((qJson) => Quiz.fromJson(qJson))
        .toList();

    return CourseDetail(
      modules: moduleList,
      quizzes: quizList,
    );
  }
}