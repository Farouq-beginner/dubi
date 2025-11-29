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
            // Header dengan Logo
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logotentang.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Pendahuluan
            _buildSectionTitle('Selamat Datang di DuBI'),
            const Text(
              'DuBI adalah aplikasi pembelajaran digital yang dirancang khusus untuk anak-anak dan remaja di Indonesia. Kami percaya bahwa belajar bisa menyenangkan! Dengan teknologi interaktif, DuBI membantu siswa dari TK hingga SMA dan Umum menguasai mata pelajaran seperti Matematika, Bahasa Indonesia, Bahasa Inggris, dan lainnya. Aplikasi ini juga dilengkapi dengan fitur sempoa, sehingga semua jenjang sekolah maupun umum bisa belajar mengenai sempoa.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Fitur Utama
            _buildSectionTitle('Fitur Utama Kami'),
            _buildFeatureCard(
              icon: Icons.school,
              title: 'Kursus Modular',
              description:
                  'Pilih kursus berdasarkan tingkat (TK, SD, SMP, SMA). Setiap kursus terdiri dari modul-modul yang mudah dipahami.',
            ),
            _buildFeatureCard(
              icon: Icons.book,
              title: 'Pelajaran Step-by-Step',
              description:
                  'Ikuti pelajaran interaktif dengan video maupun teks untuk pengalaman belajar yang menarik.',
            ),
            _buildFeatureCard(
              icon: Icons.quiz,
              title: 'Kuis Otomatis',
              description:
                  'Uji pengetahuan Anda dengan kuis yang disesuaikan jenjang sekolah dan dapat meilhat skor dengan cepat.',
            ),
            _buildFeatureCard(
              icon: Icons.dashboard,
              title: 'Dashboard Siswa',
              description:
                  'Pantau progress Anda melalui statistik, melihat progres kursus, dan riwayat kuis yang telah anda ikuti',
            ),
            _buildFeatureCard(
              icon: Icons.star,
              title: 'Mode Sempoa',
              description:
                  'Fitur eksklusif untuk pembelajaran mendalam, dengan fokus pada pemahaman konsep.',
            ),
            const SizedBox(height: 24),

            // Misi, Visi, Nilai
            _buildSectionTitle('Misi, Visi, dan Nilai Kami'),
            const Text(
              'Misi: Menyediakan akses pendidikan berkualitas tinggi bagi semua siswa Indonesia, tanpa batasan geografis atau ekonomi.\n\nVisi: Menjadi pionir dalam revolusi pendidikan digital di Asia Tenggara, dengan jutaan siswa yang berhasil mencapai impian mereka.\n\nNilai: Inovasi, Kesetaraan, dan Kesuksesan – Kami berkomitmen untuk membuat belajar inklusif dan menyenangkan.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // FAQ
            _buildSectionTitle('Pertanyaan yang Sering Diajukan (FAQ)'),
            _buildFaqItem(
              question: 'Apakah aplikasi ini gratis?',
              answer: 'Ya, aplikasi DuBi dapat diakses secara gratis.',
            ),
            _buildFaqItem(
              question: 'Apakah data saya aman?',
              answer:
                  'Kami menggunakan enkripsi untuk melindungi data pribadi Anda.',
            ),
            _buildFaqItem(
              question: 'Siapa yang bisa menggunakan DuBi?',
              answer:
                  'Siswa TK hingga SMA dan umum, serta guru dan orang tua untuk memantau progress.',
            ),
            const SizedBox(height: 24),

            // Tim Pengembang
            _buildSectionTitle('Tim Pengembang'),
            const Text(
              'DuBI dikembangkan oleh kelompok 4 mata kuliah basis data\nAnggota Pengembang :\n1. Farouq Gusmo Abdilah (24111814081)\n2. Diky Ari Setiawan (24111814135)\n3. Dewi Berliana (24111814003)\n4. Elysa Hayu Noorhaini (24111814078)',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Footer
            const Divider(),
            Center(
              child: Column(
                children: const [
                  Text(
                    'Versi 1.0.0 | © 2025 Kelompok 4 Basis data',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
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

  Widget _buildTestimonial(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
        ),
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
