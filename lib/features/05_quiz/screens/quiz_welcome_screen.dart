// lib/features/05_quiz/screens/quiz_welcome_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/services/data_service.dart';
import 'quiz_screen.dart'; // Layar tujuan

class QuizWelcomeScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  const QuizWelcomeScreen({Key? key, required this.quizId, required this.quizTitle}) : super(key: key);

  @override
  State<QuizWelcomeScreen> createState() => _QuizWelcomeScreenState();
}

class _QuizWelcomeScreenState extends State<QuizWelcomeScreen> {
  // Kita tetap butuh 'fetchQuizDetails' untuk mendapatkan info (durasi, jumlah soal)
  late Future<Quiz> _quizFuture;
  late DataService _dataService; 

  @override
  void initState() {
    super.initState();
    _dataService = DataService(context); 
    // Panggil API Siswa (QuizController@show) untuk dapat data info
    _quizFuture = _dataService.fetchQuizDetails(widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Quiz>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Kuis tidak ditemukan."));
          }

          final quiz = snapshot.data!;
          final questions = quiz.questions ?? [];

          return Column(
            children: [
              Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Konten Utama ---
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.deepPurple, size: 80),
                      const SizedBox(height: 16),
                      Text(quiz.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text("Siap untuk menguji pemahaman Anda?", style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      
                      // --- Info Kuis ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(label: 'Pertanyaan', value: '${questions.length} Soal', color: Colors.blue),
                          _InfoChip(label: 'Durasi', value: quiz.duration != null ? '${quiz.duration} Menit' : 'Bebas', color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Petunjuk ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.yellow[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.yellow.shade600)),
                        child: Text(
                          "• Baca setiap pertanyaan dengan teliti.\n• Kuis akan tersimpan otomatis jika waktu habis atau Anda keluar.",
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- Tombol Mulai ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('MULAI KUIS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // [PERBAIKAN DI SINI]
                    // Kirim quizId dan quizTitle ke QuizScreen, sesuai permintaannya
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          quizId: widget.quizId, // <-- [FIX] Gunakan widget.quizId
                          quizTitle: widget.quizTitle, // <-- [FIX] Gunakan widget.quizTitle
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
              ),
            ],
          );
        },
      ),
    );
  }
}

// Widget helper untuk chip info
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}