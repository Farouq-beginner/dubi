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
import 'package:google_fonts/google_fonts.dart';

// Tipe data helper untuk menampung kedua future
class BrowseData {
  final List<Level> levels;
  final List<Subject> subjects;
  final List<Course> allCourses;
  BrowseData({
    required this.levels,
    required this.subjects,
    required this.allCourses,
  });
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen>
    with SingleTickerProviderStateMixin {
  late Future<BrowseData> _browseDataFuture;
  late DataService _dataService; // Deklarasikan DataService
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _staggerController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context); // Inisialisasi di sini
    _browseDataFuture = _loadBrowseData();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
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
      subjects: results[1] as List<Subject>,
      allCourses: [],
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
    final String displayName = rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Pengguna';

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
            final levels =
                snapshot.data!.levels
                    .where((l) => l.levelName.toUpperCase() != 'UMUM')
                    .toList()
                  ..sort(
                    (a, b) => orderLevels
                        .indexOf(a.levelName.toUpperCase())
                        .compareTo(
                          orderLevels.indexOf(b.levelName.toUpperCase()),
                        ),
                  );

            // Filter: Hilangkan 'Membaca', 'Berhitung' dan 'Sempoa' (Sempoa pindah ke Aksi Cepat)
            final orderSubjects = [
              'Bahasa Indonesia',
              'Bahasa Inggris',
              'Matematika',
              'Fisika',
              'Umum',
            ];
            final subjects =
                snapshot.data!.subjects
                    .where(
                      (s) =>
                          s.subjectName != 'Membaca' &&
                          s.subjectName != 'Berhitung' &&
                          s.subjectName != 'Sempoa',
                    )
                    .toList()
                  ..sort(
                    (a, b) => orderSubjects
                        .indexOf(a.subjectName)
                        .compareTo(orderSubjects.indexOf(b.subjectName)),
                  );
            // final allCourses = snapshot.data!.allCourses; // currently unused

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                AnimatedBuilder(
                  animation:
                      _staggerController, // Menggunakan controller yang sudah ada untuk sinkronisasi
                  builder: (context, child) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final headerOpacity = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _staggerController,
                            curve: const Interval(
                              0.0,
                              0.3,
                              curve: Curves.easeIn,
                            ), // Muncul duluan sebelum tiles
                          ),
                        );
                    final headerSlide =
                        Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _staggerController,
                            curve: const Interval(
                              0.0,
                              0.3,
                              curve: Curves.easeOut,
                            ),
                          ),
                        );

                    return FadeTransition(
                      opacity: headerOpacity,
                      child: SlideTransition(
                        position: headerSlide,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 16.0,
                          ),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.8,
                            ), // Background semi-transparan untuk kesan floating
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Greeting Text
                              Text(
                                'Halo, $displayName! 👋',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth > 600 ? 32 : 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D3748),
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Subtitle Text
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE6F0FF),
                                      Color(0xFFBFD9FF),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Level up kemampuan kamu hari ini!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF004AAD),
                                    height: 1.3,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                    return _LevelTile(
                      level: level,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LevelCoursesScreen(level: level),
                          ),
                        );
                      },
                    );
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
                    return _SubjectTile(
                      subject: subject,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SubjectCoursesScreen(subject: subject),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Aksi Cepat
                const SizedBox(height: 16),
                const Text(
                  'Aksi Cepat',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 370;
                    if (isCompact) {
                      return Column(
                        children: [
                          _QuickActionCardWithImage(
                            imagePath: 'assets/images/icon_sempoa.png',
                            iconBg: const Color(0xFFF1E8FF),
                            title: 'Sempoa',
                            subtitle: 'Mainkan',
                            onTap: () =>
                                MainContainerScreen.switchTo(context, 3),
                          ),
                          const SizedBox(height: 12),
                          _QuickActionCard(
                            icon: Icons.insights_outlined,
                            iconBg: const Color(0xFFEAF8EF),
                            iconColor: const Color(0xFF2DBE66),
                            title: 'Dashboard',
                            subtitle: 'Lihat progress',
                            onTap: () =>
                                MainContainerScreen.switchTo(context, 2),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            imagePath: 'assets/images/icon_sempoa.png',
                            iconBg: const Color(0xFFF1E8FF),
                            iconColor: const Color(0xFF7A5CFF),
                            title: 'Sempoa',
                            subtitle: 'Mainkan',
                            onTap: () =>
                                MainContainerScreen.switchTo(context, 3),
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
                            onTap: () =>
                                MainContainerScreen.switchTo(context, 2),
                          ),
                        ),
                      ],
                    );
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

  static (Widget, Color) _style(String name) {
    switch (name.toUpperCase()) {
      case 'TK':
        return (
          Image.asset('assets/images/icon_tk.png', width: 48, height: 48),
          const Color(0xFFFFE6EF),
        );
      case 'SD':
        return (
          Image.asset('assets/images/icon_sd.png', width: 48, height: 48),
          const Color(0xFFFFE6EF),
        );
      case 'SMP':
        return (
          Image.asset('assets/images/icon_smp.png', width: 48, height: 48),
          const Color(0xFFFFE6EF),
        );
      case 'SMA':
        return (
          Image.asset('assets/images/icon_sma.png', width: 48, height: 48),
          const Color(0xFFFFE6EF),
        );
      default:
        return (
          Image.asset('assets/images/icon_default.png', width: 48, height: 48),
          const Color(0xFFFFE6EF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (iconWidget, bubble) = _style(level.levelName);
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: bubble,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: iconWidget),
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

  // Fungsi menentukan gambar dan warna latar
  static (String, Color) _style(String name) {
    if (name.contains('Indonesia')) {
      return ('assets/images/icon_b.indo.png', const Color(0xFFFFEFEF));
    }
    if (name.contains('Inggris')) {
      return ('assets/images/icon_b.inggris.png', const Color(0xFFEAF2FF));
    }
    if (name.contains('Matematika')) {
      return ('assets/images/icon_matematika.png', const Color(0xFFEFFAF3));
    }
    if (name.contains('Sempoa')) {
      return ('assets/images/icon_sempoa.png', const Color(0xFFF4EFFF));
    }
    if (name.contains('Fisika')) {
      return ('assets/images/icon_fisika.png', const Color(0xFFE8F4FF));
    }
    if (name.contains('Umum')) {
      return ('assets/images/icon_umum.png', const Color(0xFFE8F4FF));
    }
    return ('assets/images/icon_default.png', const Color(0xFFF1F3F5));
  }

  @override
  Widget build(BuildContext context) {
    final (imagePath, bubbleColor) = _style(subject.subjectName);
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Interactive',
                  style: TextStyle(
                    color: Color(0xFF7A5CFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  final IconData? icon;
  final String? imagePath;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionCard({
    this.icon,
    this.imagePath,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imagePath != null
                  ? Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(imagePath!, fit: BoxFit.contain),
                    )
                  : Icon(icon!, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCardWithImage extends StatelessWidget {
  final String imagePath;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCardWithImage({
    required this.imagePath,
    required this.iconBg,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
