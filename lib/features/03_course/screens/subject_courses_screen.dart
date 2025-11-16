// lib/features/03_course/screens/subject_courses_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/services/data_service.dart';
import '../../01_dashboard/widgets/course_card_item.dart';
import 'course_detail_screen.dart';

class SubjectCoursesScreen extends StatefulWidget {
  final Subject subject;
  const SubjectCoursesScreen({super.key, required this.subject});

  @override
  State<SubjectCoursesScreen> createState() => _SubjectCoursesScreenState();
}

class _SubjectCoursesScreenState extends State<SubjectCoursesScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panggil API baru kita
    _coursesFuture = DataService(
      context,
    ).fetchCoursesBySubject(widget.subject.subjectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject.subjectName,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 31, 184),
                Color.fromARGB(255, 77, 80, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          // ... (Handling Error/Loading/Empty sama seperti LevelCoursesScreen) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Belum ada kursus untuk mata pelajaran ${widget.subject.subjectName}.',
              ),
            );
          }

          final courses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: CourseCardItem(
                  course: course,
                  // Show the course level in badge if available
                  levelTag: course.level?.levelName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailScreen(course: course),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
