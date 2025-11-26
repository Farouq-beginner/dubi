// lib/features/01_dashboard/screens/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/course_model.dart';
import '../../03_course/screens/create_course_screen.dart';
import '../../01_dashboard/screens/teacher_courses_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late DataService _dataService;
  late Future<List<Course>> _myCoursesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _myCoursesFuture = _dataService.fetchMyCourses();
  }

  Future<void> _refresh() async {
    setState(() {
      _myCoursesFuture = _dataService.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final displayName = (auth.user?.fullName ?? '').trim();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Course>>(
          future: _myCoursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Gagal memuat dashboard.'));
            }
            final courses = snapshot.data ?? const <Course>[];

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  displayName.isNotEmpty
                      ? 'Dashboard Guru — $displayName'
                      : 'Dashboard Guru',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola kursus dan kuis Anda di sini',
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 24),
                // Ringkas statistik sederhana
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.school,
                      label: 'Kursus Saya',
                      value: courses.length.toString(),
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Aksi cepat
                Text('Aksi cepat', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionButton(
                      icon: Icons.add,
                      label: 'Buat Kursus',
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
                        );
                        if (!mounted) return;
                        _refresh();
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.collections_bookmark,
                      label: 'Kursus Saya',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherCoursesScreen()),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text('Kursus terbaru', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (courses.isEmpty)
                  const Text('Belum ada kursus. Mulai dengan membuat kursus baru.'),
        ...courses.take(5).map((c) => ListTile(
                      leading: const Icon(Icons.book_outlined),
                      title: Text(c.title),
          subtitle: Text(c.subject.subjectName),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
