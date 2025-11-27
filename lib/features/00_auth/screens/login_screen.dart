// lib/features/00_auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
    // Ambil status update dari AuthProvider (diset oleh AuthCheckScreen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateFromProviderOrNetwork();
    });
  }

  // 🔍 Cek versi (Logika Lokal)
  // Update check now controlled by AuthCheckScreen via AuthProvider
  Future<void> _checkUpdateFromProviderOrNetwork() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // If AuthCheckScreen already set flag, honor it
    if (auth.updateRequired) {
      _updateRequired = true;
      final info = auth.updateInfo ?? {};
      final url = (info['download_url'] ?? '').toString();
      final changelog = (info['changelog'] ?? 'Pembaruan tersedia.').toString();
      _showForceUpdateDialog(url, changelog);
      return;
    }

    // Otherwise, perform a quick network check to ensure dialog appears
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
      final base = auth.dio.options.baseUrl;
      final root = base.endsWith('/api/') ? base.substring(0, base.length - 5) : base;
      final uri = Uri.parse('$root/api/check-update?build_number=$currentBuild');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final latestBuild = int.tryParse(decoded['latest_build']?.toString() ?? '0') ?? 0;
          final forceUpdate = decoded['update_required'] == true;
          final downloadUrl = decoded['download_url']?.toString() ?? '';
          final changelog = decoded['changelog']?.toString() ?? 'Pembaruan tersedia.';
          if (forceUpdate && latestBuild > currentBuild) {
            _updateRequired = true;
            auth.setUpdateRequirement(required: true, info: {
              'latest_build': latestBuild,
              'download_url': downloadUrl,
              'changelog': changelog,
            });
            if (!mounted) return;
            _showForceUpdateDialog(downloadUrl, changelog);
          }
        }
      }
    } catch (e) {
      // ignore errors; login remains available
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