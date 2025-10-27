// lib/features/01_dashboard/screens/student_progress_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/student_dashboard_model.dart';
import '../../../core/services/data_service.dart';

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
              return Center(child: Text("Error: ${snapshot.error.toString()}"));
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
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // [PERBAIKAN] Sesuaikan rasio agar lebih lebar (Horizontal)
                  childAspectRatio: 2,
                  children: [
                    _buildStatCard('Course Selesai', stats.coursesCompleted.toString(), Icons.check_circle_outline, Colors.green),
                    _buildStatCard('Kuis Lulus', stats.quizzesPassed.toString(), Icons.emoji_events_outlined, Colors.purple),
                    _buildStatCard('Streak Terpanjang', '0 hari', Icons.local_fire_department_outlined, Colors.orange), // Placeholder
                    _buildStatCard('Favorit', 'Bahasa', Icons.star_outline, Colors.blue), // Placeholder
                  ],
                ),
                
                // 3. Progres Kursus Kamu
                _buildSectionTitle('Progres Kursus Kamu'),
                if (dashboard.courseProgress.isEmpty)
                  _buildEmptyState('Kamu belum mendaftar kursus apapun.'),
                ...dashboard.courseProgress.map((item) => _buildCourseProgressCard(item)),

                // 4. Riwayat Kuis Terbaru
                _buildSectionTitle('Riwayat Kuis Terbaru'),
                if (dashboard.recentQuizHistory.isEmpty)
                  _buildEmptyState('Kamu belum mengerjakan kuis apapun.'),
                ...dashboard.recentQuizHistory.map((item) => _buildQuizHistoryTile(item)),
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
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
  
  Widget _buildEmptyState(String message) {
     return Center(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    ));
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
  boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progress Keseluruhan', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 12),
              Text('Rata-rata Nilai', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 4),
              Text('Weekly Goal', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${averageScore.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('0/10 jam', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))), // Placeholder
            ],
          ),
        ],
      ),
    );
  }

  // --- [PERBAIKAN DI SINI] Layout diubah ke Row & Ukuran di-tweak ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // <-- Padding diperkecil
        child: Row( // <-- Gunakan Row
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
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // <-- Font diperkecil
                  Text(
                    title, 
                    style: TextStyle(color: Colors.grey[600], fontSize: 13), // <-- Font diperkecil
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
            Text(item.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: item.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${item.progressPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Selesai ${item.completedLessons} dari ${item.totalLessons} materi.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHistoryTile(RecentQuizAttempt item) {
    final scoreColor = item.score >= 80 ? Colors.green : (item.score >= 60 ? Colors.orange : Colors.red);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor,
          child: Text(
            item.score.toStringAsFixed(0), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item.quizTitle),
        subtitle: const Text('Skor Tertinggi'),
        trailing: Text(item.completedAt.substring(0, 10), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ),
    );
  }
}