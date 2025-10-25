// screens/quiz_result_screen.dart
import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final double score;
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
    String message;
    IconData icon;
    Color color;

    if (score >= 80) {
      message = 'Luar Biasa!';
      icon = Icons.star;
      color = Colors.green;
    } else if (score >= 60) {
      message = 'Bagus, Tingkatkan Lagi!';
      icon = Icons.thumb_up;
      color = Colors.blue;
    } else {
      message = 'Ayo Coba Lagi!';
      icon = Icons.sentiment_dissatisfied;
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
              Icon(icon, size: 120, color: color),
              SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
              SizedBox(height: 16),
              Text(
                'SKOR ANDA:',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              Text(
                '${score.toStringAsFixed(0)}', // Tampilkan skor bulat
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 24),
              Text(
                'Kamu benar $correctAnswers dari $totalQuestions pertanyaan.',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                onPressed: () {
                  // Kembali 2x (lewat QuizScreen, ke CourseDetailScreen)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text('Kembali ke Dashboard', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}