import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:dubi/features/screens/auth_check_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _logoOpacityAnim;
  late final Animation<double> _glowAnim;
  late final Animation<double> _loadingOpacityAnim;
  late final Animation<double> _loadingScaleAnim;
  late final Animation<double> _backgroundAnim;
  late final Animation<double> _3DRotationAnim; // Animasi 3D baru

  @override
  void initState() {
    super.initState();

    // Controller dengan durasi lebih panjang
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo scale
    _scaleAnim = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Logo rotation
    _rotationAnim = Tween<double>(
      begin: -0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Logo opacity
    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Glow pulse
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Background gradien animasi
    _backgroundAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Loading
    _loadingOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
    _loadingScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Animasi 3D: Rotasi Y pada logo (flip effect)
    _3DRotationAnim = Tween<double>(begin: 3.14, end: 0.0).animate(
      // Mulai dari 180 derajat (pi)
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.6,
          1.0,
          curve: Curves.easeInOut,
        ), // Mulai setelah logo muncul
      ),
    );

    // Start animasi
    _controller.forward();

    // Timer navigasi
    Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Brand colors
  static const Color brandBlue = Color(0xFF0A4FAC);
  static const Color brandBlueLight = Color(0xFF1E6DE5);
  static const Color brandPurple = Color(0xFF6A0DAD);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnim,
        builder: (context, child) {
          final bgColor1 = Color.lerp(
            brandBlue,
            brandPurple,
            _backgroundAnim.value,
          )!;
          final bgColor2 = Color.lerp(
            brandBlueLight,
            brandBlue,
            _backgroundAnim.value,
          )!;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColor1, bgColor2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo + glow + 3D rotation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final glowVal = _glowAnim.value;
                        final blur = 50.0 * glowVal;
                        final glowOpacity = 0.4 * (0.5 + 0.5 * glowVal);

                        return Opacity(
                          opacity: _logoOpacityAnim.value,
                          child: Transform.rotate(
                            angle: _rotationAnim.value,
                            child: Transform.scale(
                              scale: _scaleAnim.value,
                              child: Transform(
                                // 3D Transform: Rotasi Y dengan perspektif
                                transform: Matrix4.identity()
                                  ..setEntry(
                                    3,
                                    2,
                                    0.001,
                                  ) // Perspektif kecil untuk 3D
                                  ..rotateY(_3DRotationAnim.value), // Rotasi 3D
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Glow dengan perspektif 3D
                                    Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(
                                          _3DRotationAnim.value * 0.5,
                                        ), // Glow ikut sedikit
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: screenSize.width * 0.6,
                                        height: screenSize.width * 0.6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              brandBlue.withOpacity(
                                                glowOpacity,
                                              ),
                                              Colors.white.withOpacity(
                                                glowOpacity * 0.5,
                                              ),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: brandBlue.withOpacity(
                                                glowOpacity,
                                              ),
                                              blurRadius: blur,
                                              spreadRadius: 10 * glowVal,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Logo dengan 3D
                                    Image.asset(
                                      "assets/logo.png",
                                      width: screenSize.width * 0.5,
                                      height: screenSize.width * 0.5,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Loading
                    FadeTransition(
                      opacity: _loadingOpacityAnim,
                      child: Transform.scale(
                        scale: _loadingScaleAnim.value,
                        child: LoadingAnimationWidget.fourRotatingDots(
                          color: const Color.fromARGB(255, 111, 236, 142),
                          size: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
