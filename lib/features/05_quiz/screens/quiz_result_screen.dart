// lib/features/05_quiz/screens/quiz_result_screen.dart
import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final dynamic score; // Bisa double atau int dari JSON
  final int totalQuestions;
  final int correctAnswers;

  const QuizResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Konversi skor ke double untuk perhitungan
    final double scoreDouble = (score as num).toDouble();
    
    String message;
    IconData icon;
    Color color;

    // Logika untuk umpan balik berdasarkan skor
    if (scoreDouble >= 80) {
      message = 'Luar Biasa!';
      icon = Icons.star_rounded;
      color = Colors.green;
    } else if (scoreDouble >= 60) {
      message = 'Bagus, Tingkatkan Lagi!';
      icon = Icons.thumb_up_alt_rounded;
      color = Colors.blue;
    } else {
      message = 'Ayo Coba Lagi!';
      icon = Icons.sentiment_dissatisfied_rounded;
      color = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Kuis'),
        backgroundColor: color,
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Ikon Umpan Balik
              Icon(icon, size: 120, color: color),
              SizedBox(height: 24),

              // 2. Pesan Umpan Balik
              Text(
                message,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // 3. Tampilan Skor
              Text(
                'SKOR ANDA:',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              Text(
                '${scoreDouble.toStringAsFixed(0)}', // Tampilkan skor bulat
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 24),

              // 4. Detail Jawaban Benar
              Text(
                'Kamu benar $correctAnswers dari $totalQuestions pertanyaan.',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 48),

              // 5. Tombol Kembali
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Kembali ke layar detail kursus (melewati QuizScreen dan QuizWelcomeScreen)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text('Kembali ke Kursus', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}