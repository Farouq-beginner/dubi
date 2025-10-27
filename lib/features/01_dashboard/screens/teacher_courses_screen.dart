// lib/features/01_dashboard/screens/teacher_courses_screen.dart
import 'package:flutter/material.dart';

import '../../../core/models/course_model.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/services/data_service.dart';
import '../../03_course/screens/course_detail_screen.dart';
import '../../03_course/screens/create_course_screen.dart';
import '../widgets/course_card_item.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  late DataService _dataService;
  late Future<List<Course>> _coursesFuture;

  // Filters
  int? _selectedLevelId; // null = Semua
  int? _selectedSubjectId; // null = Semua

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _coursesFuture = _dataService.fetchMyCourses();
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _dataService.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Course'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final courses = snapshot.data ?? const <Course>[];

            // Derive Level & Subject options from courses
            final levelMap = <int, Level>{};
            final subjectMap = <int, Subject>{};
            for (final c in courses) {
              if (c.level != null) levelMap[c.level!.levelId] = c.level!;
              subjectMap[c.subject.subjectId] = c.subject;
            }
            final levels = levelMap.values.toList()
              ..sort((a, b) => a.levelName.compareTo(b.levelName));
            final subjects = subjectMap.values.toList()
              ..sort((a, b) => a.subjectName.compareTo(b.subjectName));

            // Apply filters
            final filtered = courses.where((c) {
              final matchLevel = _selectedLevelId == null || (c.level?.levelId == _selectedLevelId);
              final matchSubject = _selectedSubjectId == null || (c.subject.subjectId == _selectedSubjectId);
              return matchLevel && matchSubject;
            }).toList();

            // No AppBar badge for teacher; chips remain visible always

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // LEVEL chips (Semua, plus detected levels)
                _FilterSection(
                  title: 'Jenjang',
                  chips: [
                    FilterChipData(label: 'Semua', selected: _selectedLevelId == null, onSelected: () {
                      setState(() => _selectedLevelId = null);
                    }),
                    ...levels.map((l) => FilterChipData(
                          label: l.levelName,
                          selected: _selectedLevelId == l.levelId,
                          onSelected: () => setState(() => _selectedLevelId = l.levelId),
                        )),
                  ],
                ),

                const SizedBox(height: 8),

                // SUBJECT chips (Semua, plus detected subjects)
                _FilterSection(
                  title: 'Mata Pelajaran',
                  chips: [
                    FilterChipData(label: 'Semua', selected: _selectedSubjectId == null, onSelected: () {
                      setState(() => _selectedSubjectId = null);
                    }),
                    ...subjects.map((s) => FilterChipData(
                          label: s.subjectName,
                          selected: _selectedSubjectId == s.subjectId,
                          onSelected: () => setState(() => _selectedSubjectId = s.subjectId),
                        )),
                  ],
                ),

                const SizedBox(height: 12),

                ...filtered.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: CourseCardItem(
                        course: c,
                        levelTag: c.level?.levelName,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(course: c),
                            ),
                          );
                        },
                      ),
                    )),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('Tidak ada kursus dengan filter saat ini.')),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CreateCourseScreen()))
              .then((_) => _refresh());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// (No AppBar badge for teacher; they can freely switch levels.)

// Helper data + section widgets for horizontal chips
class FilterChipData {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  FilterChipData({required this.label, required this.selected, required this.onSelected});
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<FilterChipData> chips;
  const _FilterSection({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...chips.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(d.label),
                      selected: d.selected,
                      onSelected: (_) => d.onSelected(),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
