// models/subject_model.dart
class Subject {
  final int subjectId;
  final String subjectName;

  Subject({required this.subjectId, required this.subjectName});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
    );
  }
}