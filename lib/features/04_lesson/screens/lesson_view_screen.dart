// screens/lesson_view_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Import
import '../../../core/models/lesson_model.dart';

class LessonViewScreen extends StatelessWidget {
  final Lesson lesson;
  const LessonViewScreen({super.key, required this.lesson});

  // Fungsi untuk membuka URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Tidak bisa membuka $urlString';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materi: ${lesson.title}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // --- Logika Interaktif ---
            if (lesson.contentType == 'video')
              _buildVideoContent(context)
            else
              _buildTextContent(),
              
          ],
        ),
      ),
    );
  }

  // Widget jika materi berupa video
  Widget _buildVideoContent(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.video_library, size: 100, color: Colors.green[700]),
          SizedBox(height: 20),
          Text(
            'Materi ini adalah video. Tekan tombol di bawah untuk membukanya di aplikasi YouTube (atau browser).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.play_arrow, color: Colors.white),
            label: Text('BUKA VIDEO', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // YouTube color
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: () async {
              try {
                if (lesson.contentBody != null) {
                  await _launchURL(lesson.contentBody!);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget jika materi berupa teks
  Widget _buildTextContent() {
    return Text(
      lesson.contentBody ?? 'Konten teks belum tersedia.',
      style: TextStyle(fontSize: 16, height: 1.5),
    );
  }
}