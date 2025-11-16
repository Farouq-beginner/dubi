// screens/auth_check_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import '../../core/providers/auth_provider.dart';
import 'package:dubi/features/00_auth/screens/login_screen.dart';
import 'package:dubi/features/99_main_container/screens/main_container_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _checkedUpdate = false;

  @override
  void initState() {
    super.initState();
    // Cek update setelah frame pertama agar context siap
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdateAndLogoutIfNeeded());
  }

  Future<void> _checkUpdateAndLogoutIfNeeded() async {
    if (_checkedUpdate) return;
    _checkedUpdate = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
      final uri = Uri.parse('http://127.0.0.1:8000/api/check-update?build_number=$currentBuild');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final latestBuild = int.tryParse(data['latest_build'].toString()) ?? currentBuild;
        final forceUpdate = data['update_required'] == true;
        if (forceUpdate && latestBuild > currentBuild) {
          // Jika user sedang login, lakukan logout otomatis
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.isLoggedIn) {
            await auth.logout();
            if (!mounted) return;
            // Setelah logout, biarkan LoginScreen yang menampilkan dialog update paksa
            setState(() {});
          }
        }
      }
    } catch (e) {
      // Abaikan error cek update, tidak mengganggu alur login normal
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isLoggedIn) {
      return const MainContainerScreen();
    } else {
      return const LoginScreen();
    }
  }
}