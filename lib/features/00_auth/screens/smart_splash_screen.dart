import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/data_service.dart';
import 'login_screen.dart';
import '../../99_main_container/screens/main_container_screen.dart';
import '../../02_profile/screens/about_app_screen.dart';

class SmartSplashScreen extends StatefulWidget {
  const SmartSplashScreen({Key? key}) : super(key: key);

  @override
  State<SmartSplashScreen> createState() => _SmartSplashScreenState();
}

class _SmartSplashScreenState extends State<SmartSplashScreen>
    with TickerProviderStateMixin {
  // Status Teks
  String _loadingText = "Memuat Konfigurasi...";

  // State
  bool _isServerDown = false;
  bool _isMultiLogin = false; // (Opsional: jika backend support flag ini)

  // Animation Controllers
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Animasi Putar (Lingkaran putus-putus)
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Animasi Redup/Nyala (Titik tiga)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Mulai Proses Booting
    _startAppInitialization();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- LOGIKA UTAMA ---
  Future<void> _startAppInitialization() async {
    final dataService = DataService(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Tahap 1: Memuat Konfigurasi (Delay buatan agar terlihat smooth)
    setState(() => _loadingText = "Memuat Konfigurasi...");
    await Future.delayed(const Duration(milliseconds: 2000));

    // Tahap 2: Memeriksa Server
    setState(() => _loadingText = "Memeriksa Server...");
    bool serverOnline = await dataService.checkServerConnection();

    if (!serverOnline) {
      setState(() {
        _isServerDown = true;
        _loadingText = ""; // Sembunyikan teks loading biasa
      });
      return; // Stop proses
    }

    // Tahap 3: Memeriksa Status Login Lokal
    setState(() => _loadingText = "Memvalidasi Pengguna...");
    await authProvider.loadUserFromStorage();

    if (authProvider.isLoggedIn) {
      // Tahap 4: Mengautentikasi ke Server (Cek Token Expired/Invalid)
      setState(() => _loadingText = "Mengautentikasi Pengguna...");
      bool sessionValid = await dataService.checkSessionValidity();

      if (sessionValid) {
        _navigateToHome();
      } else {
        // --- [PERBAIKAN DI SINI] ---
        // Jika sesi tidak valid (misal: login di device lain),
        // JANGAN langsung navigate. Tampilkan dialog dulu.

        await authProvider.logout(); // Hapus data lokal

        if (!mounted) return;

        // Tampilkan Dialog dan TUNGGU user menekan OK
        await showDialog(
          context: context,
          barrierDismissible: false, // User WAJIB tekan tombol
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Sesi Berakhir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Akun Anda telah login di perangkat lain atau sesi telah habis.\n\nSilakan login kembali.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Tutup Dialog
                },
                child: const Text('OK, Ke Halaman Login'),
              ),
            ],
          ),
        );

        // Setelah dialog ditutup, BARU pindah ke Login
        _navigateToLogin();
      }
    } else {
      // Belum login sama sekali
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainContainerScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _retryConnection() {
    setState(() {
      _isServerDown = false;
      _startAppInitialization();
    });
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Warna background gelap modern (seperti gambar)
      body: Stack(
        children: [
          // Background gradient tipis (opsional)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),

          Center(
            child: _isServerDown ? _buildServerDownView() : _buildLoadingView(),
          ),
        ],
      ),
    );
  }

  // Tampilan 1: Loading Normal (Logo + Teks Berubah)
  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset('assets/logo.png', width: 300, height: 300),
        const SizedBox(height: 150),

        // Loading Animation & Text
        Column(
          children: [
            // Teks Status Berubah-ubah
            Text(
              _loadingText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            // Indikator Loading (Garis lurus atau lingkaran kecil)
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.blueAccent,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tampilan 2: Server Down (Sesuai Gambar)
  Widget _buildServerDownView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animasi Lingkaran Putus-putus Berputar mengelilingi Logo
          Stack(
            alignment: Alignment.center,
            children: [
              // Lingkaran Putar
              RotationTransition(
                turns: _rotateController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                      width: 3,
                      style: BorderStyle
                          .solid, // Flutter border dash susah native, pakai solid transparansi atau CustomPainter
                    ),
                    gradient: const SweepGradient(
                      colors: [Colors.transparent, Colors.blueAccent],
                    ),
                  ),
                ),
              ),
              // Logo Diam di Tengah
              Image.asset('assets/logo.png', width: 80, height: 80),
            ],
          ),

          const SizedBox(height: 40),

          // Kotak Pesan
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Text(
                  "Sistem Sedang Dalam Pemeliharaan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Server Sedang Down, Mohon Bersabar",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Titik Tiga Animasi (Sistem sedang diperbarui)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 8),
                    _buildDot(0.5),
                    const SizedBox(width: 8),
                    _buildDot(1.0),
                    const SizedBox(width: 12),
                    Flexible(
                      child: const Text(
                        "Sistem sedang diperbarui",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Tombol Aksi
          _buildActionButton(
            label: "About Us",
            icon: Icons.people,
            color: Colors.blueAccent,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutAppScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: "Restart Aplikasi",
            icon: Icons.refresh,
            color: Colors.white10,
            onTap: _retryConnection,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return FadeTransition(
      opacity: _pulseController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
