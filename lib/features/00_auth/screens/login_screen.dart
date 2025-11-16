import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _updateRequired = false; // 🔒 jika true, login dikunci

  @override
  void initState() {
    super.initState();
    _checkAppUpdate();
  }

  // 🔍 Cek versi ke API Laravel
  Future<void> _checkAppUpdate() async {
    try {
      print('🔍 Memeriksa update...');
      final packageInfo = await PackageInfo.fromPlatform();
      int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final response = await http.get(
        Uri.parse(
          'https://dubibackend-production.up.railway.app/api/check-update?build_number=$currentBuild',
        ),
      );

      print('📥 Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Body: $data');

        int latestBuild = int.tryParse(data['latest_build'].toString()) ?? 1;
        bool forceUpdate = data['update_required'] ?? false;
        String downloadUrl = data['download_url'] ?? '';
        String changelog = data['changelog'] ?? '';

        print(
          '📱 Current build: $currentBuild | 🔄 Latest build: $latestBuild',
        );

        if (forceUpdate && latestBuild > currentBuild) {
          setState(() => _updateRequired = true);

          // 🔒 tampilkan dialog wajib update (tidak bisa ditutup)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showForceUpdateDialog(downloadUrl, changelog);
          });
        } else {
          print('✅ Aplikasi sudah versi terbaru.');
        }
      } else {
        print('⚠️ Gagal cek update.');
      }
    } catch (e) {
      print('❌ Error cek update: $e');
    }
  }

  void _showForceUpdateDialog(String url, String changelog) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ tidak bisa ditutup manual
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // ❌ tidak bisa tekan back
        child: AlertDialog(
          title: const Text(
            '⚠️ Pembaruan Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(changelog),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Unduh Sekarang',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 4, 31, 184),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔑 Login
  Future<void> _handleLogin() async {
    if (_updateRequired) {
      // 🚫 Blokir login jika update wajib
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan perbarui aplikasi ke versi terbaru untuk melanjutkan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(_emailController.text, _passwordController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
                Icon(
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
                  enabled:
                      !_updateRequired, // ❌ nonaktifkan input jika wajib update
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
                        color: Color.fromARGB(255, 4, 31, 184),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _updateRequired
                        ? null
                        : _handleLogin, // 🚫 tidak aktif saat wajib update
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _updateRequired
                          ? Colors.grey
                          : Color.fromARGB(255, 4, 31, 184),
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
                    'Belum punya akun? Daftar di sini',
                    style: TextStyle(
                      color: Color.fromARGB(255, 4, 31, 184),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
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
                      fontSize: 16,
                    ),
                  ),
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
        borderSide: BorderSide(color: Color.fromARGB(255, 4, 31, 184)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 4, 31, 184),
          width: 2,
        ),
      ),
    );
  }
}
