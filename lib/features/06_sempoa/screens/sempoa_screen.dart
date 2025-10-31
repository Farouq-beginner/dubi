// lib/features/06_sempoa/screens/sempoa_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/sempoa_progress_model.dart';
import 'sempoa_challenge_screen.dart';
import 'leaderboard_screen.dart';

class SempoaScreen extends StatefulWidget {
  const SempoaScreen({super.key});

  @override
  State<SempoaScreen> createState() => _SempoaScreenState();
}

class _SempoaScreenState extends State<SempoaScreen> {
  late Future<SempoaProgress> _progressFuture;
  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context);
    _progressFuture = _dataService.fetchSempoaProgress(); // Ambil progres awal
  }

  // Navigasi ke layar Game
  void _startChallenge(SempoaProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SempoaChallengeScreen(initialProgress: progress),
      ),
    ).then((_) {
      // Setelah kembali dari challenge, muat ulang progres agar
      // Level/Skor/Streak terbaik ter-update di kartu utama
      setState(() {
        _progressFuture = _dataService.fetchSempoaProgress();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SempoaProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Tampilkan error jika API gagal
            return Center(
              child: Text('Gagal memuat Sempoa: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data progres tidak ditemukan.'));
          }

          final progress = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _progressFuture = _dataService.fetchSempoaProgress();
              });
              await _progressFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
            children: [
              // Header (Sesuai gambar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7A5CFF), Color(0xFF2F6BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.grid_on, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sempoa Digital',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Belajar berhitung dengan sempoa',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Kartu "Sempoa Master" (Sesuai gambar)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    children: [
                      // Ikon (lebih modern)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7A5CFF), Color(0xFF2F6BFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),

                      // Teks
                      Text(
                        'Sempoa Master',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latihan berhitung cepat dengan sempoa',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 16),
                      Text(
                        'Level Tertinggi: ${progress.highestLevel}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        'Skor Terbaik: ${progress.highScore}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Streak Terbaik: ${progress.highestStreak}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Tombol
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        label: const Text(
                          'Mainkan Sempoa',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A5CFF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _startChallenge(progress),
                      ),
                      const SizedBox(height: 12),
                      // Tombol Leaderboard
                      OutlinedButton.icon(
                        icon: const Icon(Icons.leaderboard, color: Colors.green),
                        label: const Text('Leaderboard', style: TextStyle(color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          side: const BorderSide(color: Color(0xFF7A5CFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cara Bermain
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.black.withOpacity(0.06))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cara Bermain:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                _Bullet(text: 'Klik beads atas (nilai 5)'),
                                SizedBox(height: 8),
                                _Bullet(text: 'Bentuk angka target'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                _Bullet(text: 'Klik beads bawah (nilai 1)'),
                                SizedBox(height: 8),
                                _Bullet(text: 'Dapatkan poin & level up'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Bullet text for Cara Bermain
class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(Icons.circle, size: 6, color: Colors.black54),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }
}
