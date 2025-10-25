// screens/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import 'package:dubi/features/00_auth/screens/login_screen.dart';
import 'package:dubi/features/99_main_container/screens/main_container_screen.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isLoggedIn) {
      return MainContainerScreen(); // <-- GANTI DARI HomeScreen
    } else {
      return LoginScreen();
    }
  }
}