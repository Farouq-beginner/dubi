// lib/features/03_course/screens/level_courses_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/level_model.dart';
import '../../../core/services/data_service.dart';
import 'package:dubi/features/01_dashboard/widgets/course_bubble_clickable.dart';
import 'course_detail_screen.dart';

class LevelCoursesScreen extends StatefulWidget {
  final Level level;
  const LevelCoursesScreen({super.key, required this.level});

  @override
  State<LevelCoursesScreen> createState() => _LevelCoursesScreenState();
}

class _LevelCoursesScreenState extends State<LevelCoursesScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panggil API baru kita
    _coursesFuture = DataService(context).fetchCoursesByLevel(widget.level.levelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.levelName),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada kursus untuk jenjang ${widget.level.levelName}.'));
          }

          final courses = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return CourseBubbleClickable(
                course: courses[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: courses[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}