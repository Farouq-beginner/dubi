// lib/features/01_dashboard/screens/student_progress_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/student_dashboard_model.dart';
import '../../../core/services/data_service.dart';
import 'package:intl/intl.dart'; // Import ini

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  late Future<StudentDashboard> _dashboardFuture;
  late DataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = DataService(context);
    _dashboardFuture = _dataService.fetchStudentDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _dataService.fetchStudentDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: FutureBuilder<StudentDashboard>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              // Pastikan konsisten: Dashboard menampilkan pesan dashboard
              return const Center(child: Text('Gagal memuat dashboard.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Tidak ada data progres."));
            }

            final dashboard = snapshot.data!;
            final stats = dashboard.statistics;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Kartu Progress Keseluruhan
                _buildOverallProgressCard(stats.averageScore),

                // 2. Statistik Pembelajaran
                _buildSectionTitle('Statistik Pembelajaran'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final double rawScale = width / 400;
                    final double textScale = rawScale
                        .clamp(0.75, 1.0)
                        .toDouble();
                    final mediaQuery = MediaQuery.of(context);

                    Widget wrapCard(Widget card) => MediaQuery(
                      data: mediaQuery.copyWith(textScaleFactor: textScale),
                      child: card,
                    );

                    final cards = <Widget>[
                      //   wrapCard(
                      //     _buildStatCard(
                      //       'Course Selesai',
                      //       stats.coursesCompleted.toString(),
                      //       Icons.check_circle_outline,
                      //       Colors.green,
                      //     ),
                      //   ),
                      wrapCard(
                        _buildStatCard(
                          'Kuis Lulus',
                          stats.quizzesPassed.toString(),
                          Icons.emoji_events_outlined,
                          Colors.purple,
                        ),
                      ),
                      // wrapCard(
                      //   _buildStatCard(
                      //     'Streak Terpanjang',
                      //     '0 hari',
                      //     Icons.local_fire_department_outlined,
                      //     Colors.orange,
                      //   ),
                      // ),
                      // wrapCard(
                      //   _buildStatCardWithImage(
                      //     'Favorit',
                      //     'Bahasa',
                      //     'assets/images/icon_bahasa.png',
                      //     Colors.blue,
                      //   ),
                      // ),
                    ];

                    if (width >= 900) {
                      return Row(
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i != 0) const SizedBox(width: 12),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      );
                    }

                    const spacing = 12.0;
                    final childWidth = (width - spacing) / 2;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final card in cards)
                          SizedBox(width: childWidth, child: card),
                      ],
                    );
                  },
                ),

                // 3. Progres Kursus Kamu
                _buildSectionTitle('Progres Kursus Kamu'),
                if (dashboard.courseProgress.isEmpty)
                  _buildEmptyState('Kamu belum mendaftar kursus apapun.'),
                ...dashboard.courseProgress.map(
                  (item) => _buildCourseProgressCard(item),
                ),

                // 4. Riwayat Kuis Terbaru
                _buildSectionTitle('Riwayat Kuis Terbaru'),
                if (dashboard.recentQuizHistory.isEmpty)
                  _buildEmptyState('Kamu belum mengerjakan kuis apapun.'),
                ...dashboard.recentQuizHistory.map(
                  (item) => _buildQuizHistoryTile(item),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Widget Helper ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard(double averageScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Keseluruhan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Rata-rata Nilai',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Weekly Goal',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${averageScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0/10 jam',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ), // Placeholder
            ],
          ),
        ],
      ),
    );
  }

  // --- [PERBAIKAN DI SINI] Layout diubah ke Row & Ukuran di-tweak ---
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // <-- Padding diperkecil
        child: Row(
          // <-- Gunakan Row
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon di kiri (dengan background)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28), // <-- Ikon diperkecil
            ),
            const SizedBox(width: 10), // <-- Spasi diperkecil
            // Teks di kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // <-- Font diperkecil
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ), // <-- Font diperkecil
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Pastikan tidak wrap
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardWithImage(
    String title,
    String value,
    String imagePath,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🖼️ Gambar pengganti ikon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseProgressCard(CourseProgressItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.courseTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: item.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.progressPercentage}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selesai ${item.completedLessons} dari ${item.totalLessons} materi.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHistoryTile(RecentQuizAttempt item) {
    final scoreColor = item.score >= 80
        ? Colors.green
        : (item.score >= 60 ? Colors.orange : Colors.red);

    // [PERBAIKAN FORMAT TANGGAL]
    String formattedDate = item.completedAt;
    try {
      DateTime date = DateTime.parse(item.completedAt).toLocal();
      formattedDate = DateFormat(
        'd MMM, HH:mm',
      ).format(date); // Contoh: 30 Nov, 10:00
    } catch (_) {}

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor,
          child: Text(
            item.score.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(item.quizTitle),
        subtitle: const Text('Skor Tertinggi'),
        // Gunakan tanggal yang sudah diformat
        trailing: Text(
          formattedDate,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }
}
