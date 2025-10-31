// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'core/providers/auth_provider.dart';
import 'features/00_auth/screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isChecking = true;
  bool _forceUpdate = false;
  String _downloadUrl = '';
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    const apiUrl = 'https://dubibackend-production.up.railway.app/api/check-update';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final PackageInfo info = await PackageInfo.fromPlatform();

        final currentVersion = info.version;
        final latestVersion = data['latest_version'];
        final forceUpdate = data['force_update'] ?? false;

        if (currentVersion != latestVersion && forceUpdate == true) {
          setState(() {
            _forceUpdate = true;
            _downloadUrl = data['download_url'];
            _latestVersion = latestVersion;
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal memeriksa pembaruan: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Saat masih memeriksa versi
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Memeriksa pembaruan...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_forceUpdate) {
      // Jika versi lama dan update wajib
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AlertDialog(
              title: const Text('Pembaruan Diperlukan ⚠️'),
              content: Text(
                'Versi terbaru ($_latestVersion) telah tersedia.\n\n'
                'Silakan unduh pembaruan agar bisa melanjutkan penggunaan aplikasi.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(_downloadUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Download Sekarang'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Jika versi sudah terbaru → lanjut ke aplikasi
    return MaterialApp(
      title: 'DuBI App',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Arial'),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
