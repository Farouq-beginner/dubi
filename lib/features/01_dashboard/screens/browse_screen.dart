// lib/features/01_dashboard/screens/browse_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/level_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/data_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../03_course/screens/level_courses_screen.dart';
import '../../03_course/screens/subject_courses_screen.dart';
import '../../99_main_container/screens/main_container_screen.dart';

// Tipe data helper untuk menampung kedua future
class BrowseData {
  final List<Level> levels;
  final List<Subject> subjects;
  final List<Course> allCourses;
  BrowseData({required this.levels, required this.subjects, required this.allCourses});
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late Future<BrowseData> _browseDataFuture;
  late DataService _dataService; // Deklarasikan DataService

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context); // Inisialisasi di sini
    _browseDataFuture = _loadBrowseData();
  }

  // Fungsi untuk memanggil kedua API secara bersamaan
  Future<BrowseData> _loadBrowseData() async {
    // Jalankan kedua API secara paralel
    final results = await Future.wait([
      _dataService.fetchLevels(),
      _dataService.fetchSubjects(),
    ]);
    return BrowseData(
      levels: results[0] as List<Level>,
      subjects: results[1] as List<Subject>, allCourses: [],
    );
  }

  // Fungsi refresh untuk Pull-to-refresh
  Future<void> _refreshBrowseData() async {
    setState(() {
      _browseDataFuture = _loadBrowseData();
    });
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // (old icon helpers removed; replaced by tile widgets below)

  @override
  Widget build(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final String rawName = auth.user?.fullName ?? '';
  final String displayName = rawName.trim().isNotEmpty ? rawName.trim() : 'Pengguna';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshBrowseData,
        child: FutureBuilder<BrowseData>(
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

            final orderLevels = ['TK', 'SD', 'SMP', 'SMA'];
            final levels = snapshot.data!.levels
                .where((l) => l.levelName.toUpperCase() != 'UMUM')
                .toList()
              ..sort((a, b) => orderLevels.indexOf(a.levelName.toUpperCase()).compareTo(
                    orderLevels.indexOf(b.levelName.toUpperCase()),
                  ));

            // Filter: Hilangkan 'Membaca', 'Berhitung' dan 'Sempoa' (Sempoa pindah ke Aksi Cepat)
            final orderSubjects = ['Bahasa Indonesia', 'Bahasa Inggris', 'Matematika'];
            final subjects = snapshot.data!.subjects
                .where((s) => s.subjectName != 'Membaca' && s.subjectName != 'Berhitung' && s.subjectName != 'Sempoa')
                .toList()
              ..sort((a, b) => orderSubjects.indexOf(a.subjectName).compareTo(
                    orderSubjects.indexOf(b.subjectName),
                  ));
            // final allCourses = snapshot.data!.allCourses; // currently unused

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Header (Sesuai gambar)
                Text(
                  'Halo, $displayName! 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ayo belajar dengan senang hati',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                // Aksi Cepat
                const SizedBox(height: 16),
                const Text('Aksi Cepat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.calculate,
                        iconBg: const Color(0xFFF1E8FF),
                        iconColor: const Color(0xFF7A5CFF),
                        title: 'Sempoa',
                        subtitle: 'Mainkan',
                        onTap: () => MainContainerScreen.switchTo(context, 3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.insights_outlined,
                        iconBg: const Color(0xFFEAF8EF),
                        iconColor: const Color(0xFF2DBE66),
                        title: 'Dashboard',
                        subtitle: 'Lihat progress',
                        onTap: () => MainContainerScreen.switchTo(context, 2),
                      ),
                    ),
                  ],
                ),

                _buildSectionTitle('Pilih Jenjang Pendidikan'),

                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // Make tiles taller to avoid overflow in content (icon + title + age)
                    mainAxisExtent: 160,
                  ),
                  itemCount: levels.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    return _LevelTile(level: level, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelCoursesScreen(level: level),
                        ),
                      );
                    });
                  },
                ),

                _buildSectionTitle('Mata Pelajaran'),

                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // Taller cells to fit optional "Interactive" pill for Sempoa
                    mainAxisExtent: 170,
                  ),
                  itemCount: subjects.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _SubjectTile(subject: subject, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectCoursesScreen(subject: subject),
                        ),
                      );
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // (old card builders removed; replaced by _LevelTile and _SubjectTile widgets below)
}

// ---------------------------- Styled Tiles ----------------------------

class _LevelTile extends StatelessWidget {
  final Level level;
  final VoidCallback onTap;
  const _LevelTile({required this.level, required this.onTap});

  static String _ageRange(String name) {
    switch (name.toUpperCase()) {
      case 'TK':
        return '4-6 tahun';
      case 'SD':
        return '7-12 tahun';
      case 'SMP':
        return '13-15 tahun';
      case 'SMA':
        return '16-18 tahun';
      default:
        return '';
    }
  }

  static (IconData, Color, Color) _style(String name) {
    // returns (icon, bubbleColor, iconColor)
    switch (name.toUpperCase()) {
      case 'TK':
        return (Icons.tag_faces, const Color(0xFFFFE6EF), const Color(0xFFFF5C8A));
      case 'SD':
        return (Icons.school_outlined, const Color(0xFFE7F0FF), const Color(0xFF3D7CFF));
      case 'SMP':
        return (Icons.school, const Color(0xFFEAF8EF), const Color(0xFF3CCB6A));
      case 'SMA':
        return (Icons.apartment_outlined, const Color(0xFFF0E9FF), const Color(0xFF8A63FF));
      default:
        return (Icons.category, const Color(0xFFF1F3F5), const Color(0xFF6B7280));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bubble, accent) = _style(level.levelName);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: bubble, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              level.levelName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _ageRange(level.levelName),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  const _SubjectTile({required this.subject, required this.onTap});

  static (IconData, Color, Color) _style(String name) {
    // returns (icon, bubbleColor, iconColor)
    if (name.contains('Indonesia')) return (Icons.translate, const Color(0xFFFFEFEF), const Color(0xFFFF6B6B));
    if (name.contains('Inggris')) return (Icons.public, const Color(0xFFEAF2FF), const Color(0xFF3D7CFF));
    if (name.contains('Matematika')) return (Icons.calculate, const Color(0xFFEFFAF3), const Color(0xFF2DBE66));
    if (name.contains('Sempoa')) return (Icons.grid_view_rounded, const Color(0xFFF4EFFF), const Color(0xFF8A63FF));
    return (Icons.menu_book, const Color(0xFFF1F3F5), const Color(0xFF6B7280));
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bubble, accent) = _style(subject.subjectName);
    final isSempoa = subject.subjectName.toLowerCase().contains('sempoa');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: bubble, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              subject.subjectName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (isSempoa) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Interactive', style: TextStyle(color: Color(0xFF7A5CFF), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------- Quick Action Card ----------------------------
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
