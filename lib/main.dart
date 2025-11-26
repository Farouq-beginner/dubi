// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart'; // Sesuaikan path
import 'features/00_auth/screens/splash_screen.dart'; // Import SplashScreen
import 'features/00_auth/screens/smart_splash_screen.dart'; // Import SmartSplashScreen

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuBI App',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Arial'),
      debugShowCheckedModeBanner: false,
      home: SmartSplashScreen(), // Gunakan SmartSplashScreen sebagai layar awal
    );
  }
}
