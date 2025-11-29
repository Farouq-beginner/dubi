import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT US', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 31, 184),
                Color.fromARGB(255, 77, 80, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO
            Center(
              child: Image.asset(
                'assets/logotentang.png',
                height: 160,
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 15),

            _buildSectionTitle('Selamat Datang di DuBI'),
            const Text(
              'DuBI adalah aplikasi pembelajaran digital yang dirancang khusus untuk anak-anak dan remaja di Indonesia. '
              'Dengan teknologi interaktif, DuBI membantu siswa menguasai berbagai pelajaran mulai dari TK hingga SMA dan Umum.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Fitur Utama Kami'),
            _buildFeatureCard(
              icon: Icons.school,
              title: 'Kursus Modular',
              description:
                  'Pilih kursus berdasarkan tingkat pendidikan dan modul yang mudah dipahami.',
            ),
            _buildFeatureCard(
              icon: Icons.book,
              title: 'Pelajaran Step-by-Step',
              description:
                  'Materi pembelajaran interaktif berupa video maupun teks.',
            ),
            _buildFeatureCard(
              icon: Icons.quiz,
              title: 'Kuis Otomatis',
              description:
                  'Uji pengetahuan dengan kuis sesuai jenjang pendidikan.',
            ),
            _buildFeatureCard(
              icon: Icons.dashboard,
              title: 'Dashboard Siswa',
              description:
                  'Pantau progress belajar, statistik, dan riwayat kuis.',
            ),
            _buildFeatureCard(
              icon: Icons.star,
              title: 'Mode Sempoa',
              description:
                  'Fitur eksklusif belajar sempoa untuk semua jenjang.',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Misi, Visi, dan Nilai Kami'),
            const Text(
              'Misi: Menyediakan akses pendidikan berkualitas bagi seluruh siswa Indonesia.\n\n'
              'Visi: Menjadi pionir pendidikan digital di Asia Tenggara.\n\n'
              'Nilai: Inovasi, Kesetaraan, dan Kesuksesan.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Pertanyaan yang Sering Diajukan (FAQ)'),
            _buildFaqItem(
              question: 'Apakah aplikasi ini gratis?',
              answer: 'Ya, aplikasi DuBI dapat diakses secara gratis.',
            ),
            _buildFaqItem(
              question: 'Apakah data saya aman?',
              answer:
                  'Kami menggunakan sistem enkripsi untuk melindungi data pengguna.',
            ),
            _buildFaqItem(
              question: 'Siapa yang bisa menggunakan DuBI?',
              answer:
                  'Siswa TK hingga SMA, serta orang tua dan guru yang ingin memantau perkembangan belajar.',
            ),
            const SizedBox(height: 24),

            // *****************************************************************
            //                     TIM PENGEMBANG — FINAL
            // *****************************************************************
            _buildSectionTitle('Tim Pengembang'),

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    const Text(
                      'Farouq Gusmo Abdilah – 24111814081\n'
                      'Diky Ari Setiawan – 24111814135\n'
                      'Dewi Berliana – 24111814003\n'
                      'Elysa Hayu Noorhaini – 24111814078',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            const Divider(),
            Center(
              child: Column(
                children: const [
                  Text(
                    'Versi 1.0.0 | © 2025 Kelompok 4 Basis Data',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    'Semua hak dilindungi undang-undang.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ================================
  // COMPONENTS
  // ================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 69, 95, 239),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Color.fromARGB(255, 4, 31, 184)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(answer, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
