// lib/features/01_dashboard/screens/browse_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/services/data_service.dart';
import '../../03_course/screens/level_courses_screen.dart';
import '../../03_course/screens/subject_courses_screen.dart';

// Tipe data helper untuk menampung kedua future
class BrowseData {
  final List<Level> levels;
  final List<Subject> subjects;
  BrowseData({required this.levels, required this.subjects});
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late Future<BrowseData> _browseDataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _browseDataFuture = _loadBrowseData();
  }

  // Fungsi untuk memanggil kedua API secara bersamaan
  Future<BrowseData> _loadBrowseData() async {
    final dataService = DataService(context);
    // Jalankan kedua API secara paralel
    final results = await Future.wait([
      dataService.fetchLevels(),
      dataService.fetchSubjects(),
    ]);
    return BrowseData(
      levels: results[0] as List<Level>,
      subjects: results[1] as List<Subject>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<BrowseData>(
        future: _browseDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final levels = snapshot.data!.levels;
          final subjects = snapshot.data!.subjects;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Judul "Pilih Jenjang" ---
              _buildSectionTitle('Pilih Jenjang Pendidikan'),
              
              // --- Grid Jenjang (TK, SD, SMP, SMA) ---
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5, // Menyesuaikan rasio kartu
                ),
                itemCount: levels.length,
                shrinkWrap: true, // Wajib di dalam ListView
                physics: const NeverScrollableScrollPhysics(), // Wajib di dalam ListView
                itemBuilder: (context, index) {
                  final level = levels[index];
                  // Kita skip "Umum" di sini agar sesuai gambar, tapi Anda bisa hapus 'if' ini
                  if (level.levelName.toLowerCase() == 'umum') return Container(); 
                  
                  return _buildLevelCard(
                    context, 
                    level: level, 
                    icon: _getIconForLevel(level.levelName),
                  );
                },
              ),
              
              // --- Judul "Mata Pelajaran" ---
              _buildSectionTitle('Mata Pelajaran'),

              // --- Grid Mata Pelajaran (Sempoa, dll) ---
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: subjects.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _buildSubjectCard(
                    context, 
                    subject: subject,
                    icon: _getIconForSubject(subject.subjectName),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper untuk Judul
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Helper untuk Ikon (sesuai gambar)
  IconData _getIconForLevel(String levelName) {
    switch (levelName.toUpperCase()) {
      case 'TK': return Icons.child_care;
      case 'SD': return Icons.school;
      case 'SMP': return Icons.auto_stories;
      case 'SMA': return Icons.workspace_premium;
      default: return Icons.category;
    }
  }

  IconData _getIconForSubject(String subjectName) {
    if (subjectName.contains('Indonesia')) return Icons.translate;
    if (subjectName.contains('Inggris')) return Icons.language;
    if (subjectName.contains('Matematika')) return Icons.functions;
    if (subjectName.contains('Sempoa')) return Icons.calculate;
    return Icons.book;
  }

  // Helper untuk Kartu Jenjang
  Widget _buildLevelCard(BuildContext context, {required Level level, required IconData icon}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LevelCoursesScreen(level: level)),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 12),
            Text(level.levelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Helper untuk Kartu Mata Pelajaran
  Widget _buildSubjectCard(BuildContext context, {required Subject subject, required IconData icon}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubjectCoursesScreen(subject: subject)),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 12),
            Text(subject.subjectName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}