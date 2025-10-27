import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:dubi/features/screens/auth_check_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthCheckScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(255, 255, 255, 1),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo utama
              Image.asset(
                "assets/logo.png",
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 5),

              // Tagline kecil miring
              Text(
                "Belajar Jadi Menyenangkan",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Animasi loading
              LoadingAnimationWidget.twistingDots(
                leftDotColor: const Color.fromARGB(255, 111, 236, 142),
                rightDotColor: const Color.fromARGB(255, 1, 118, 176),
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
