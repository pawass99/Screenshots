import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after a short delay
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                // Centered logo
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Image.asset(
                        'assets/splash.png',
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.9,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'MakanDimana',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom-right color swatches
                Positioned(
                  right: 18,
                  bottom: 24,
                  child: Row(
                    children: [
                      Container(width: 18, height: 18, color: const Color(0xFFFF7A20)),
                      const SizedBox(width: 6),
                      Container(width: 18, height: 18, color: const Color(0xFFFF4A3F)),
                      const SizedBox(width: 6),
                      Container(width: 18, height: 18, color: const Color(0xFFB83B43)),
                      const SizedBox(width: 6),
                      Container(width: 18, height: 18, color: const Color(0xFF7A2E33)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
