// lib/features/00_auth/screens/login_screen.dart
import 'dart:convert';
import 'dart:io'; // Untuk deteksi Platform
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../99_main_container/screens/main_container_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _updateRequired = false; 

  @override
  void initState() {
    super.initState();
    // Jalankan cek update setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
  }

  // 🔍 Cek versi (Logika Lokal)
  Future<void> _checkAppUpdate() async {
    try {
      print('🔍 Memeriksa update...');
      final packageInfo = await PackageInfo.fromPlatform();
      int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      // Tentukan URL berdasarkan Platform (Android Emulator butuh 10.0.2.2)
      String baseUrl = 'http://127.0.0.1:8000';
      if (!kIsWeb && Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8000';
      }

      final response = await http.get(Uri.parse(
        '$baseUrl/api/check-update?build_number=$currentBuild',
      )).timeout(const Duration(seconds: 5)); // Tambah timeout agar tidak hang

      print('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // [PERBAIKAN] Pastikan data adalah Map dan tidak null
        if (data != null && data is Map<String, dynamic>) {
          print('📦 Body: $data');

          // Ambil data dengan aman (menggunakan ?.)
          int latestBuild = int.tryParse(data['latest_build']?.toString() ?? '0') ?? 0;
          bool forceUpdate = data['update_required'] ?? false;
          String downloadUrl = data['download_url'] ?? '';
          String changelog = data['changelog'] ?? 'Pembaruan tersedia.';

          print('📱 Current: $currentBuild | 🔄 Latest: $latestBuild');

          // Logika membandingkan versi
          if (forceUpdate && latestBuild > currentBuild) {
            if (!mounted) return;
            setState(() => _updateRequired = true);
            _showForceUpdateDialog(downloadUrl, changelog);
          } else {
            print('✅ Aplikasi sudah versi terbaru.');
          }
        }
      } else {
        print('⚠️ Gagal cek update: Server error ${response.statusCode}');
      }
    } catch (e) {
      // Error jaringan (misal offline) diabaikan agar user tetap bisa login
      print('❌ Error cek update (Diabaikan): $e');
    }
  }

  void _showForceUpdateDialog(String url, String changelog) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ tidak bisa ditutup manual
      builder: (context) => PopScope(
        canPop: false, // ❌ Mencegah tombol back Android
        child: AlertDialog(
          title: const Text(
            '⚠️ Pembaruan Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Versi baru tersedia! Anda harus memperbarui aplikasi untuk melanjutkan.'),
              const SizedBox(height: 10),
              const Text('Apa yang baru:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(changelog),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                if (url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Unduh Sekarang', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 4, 31, 184),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔑 Login
  Future<void> _handleLogin() async {
    // 1. Cek Update Required
    if (_updateRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan perbarui aplikasi ke versi terbaru untuk melanjutkan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validasi Input
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email dan Password wajib diisi'), backgroundColor: Colors.orange),
        );
        return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 3. Panggil Provider Login
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(_emailController.text, _passwordController.text);
      
      if (!mounted) return;

      // 4. Navigasi Sukses (Hapus route history agar tidak bisa back ke login)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainContainerScreen()),
        (route) => false,
      );

    } catch (e) {
      // 5. Handle Error Login
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school,
                  size: 100,
                  color: Color.fromARGB(255, 4, 31, 184),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 4, 31, 184),
                  ),
                ),
                const Text(
                  'Masuk untuk mulai belajar',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('Email kamu'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_updateRequired, 
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_updateRequired,
                  decoration: _buildInputDecoration('Password kamu').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color.fromARGB(255, 4, 31, 184),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                 // Tombol Lupa Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _updateRequired
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 4, 31, 184),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _updateRequired ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _updateRequired
                          ? Colors.grey
                          : const Color.fromARGB(255, 4, 31, 184),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'MASUK',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? "),
                    TextButton(
                      onPressed: _updateRequired
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Daftar di sini',
                        style: TextStyle(
                          color: Color.fromARGB(255, 4, 31, 184),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color.fromARGB(255, 4, 31, 184)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 4, 31, 184),
          width: 2,
        ),
      ),
    );
  }
}