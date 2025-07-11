import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Start animation timer
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });
    // Start navigation timer
    Timer(const Duration(seconds: 4), _navigateUser);
  }

  void _navigateUser() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW PINK COLOR PALETTE ---
    const Color topGradientColor = Color(0xFFFDECF2); // A very light, soft pink
    const Color bottomGradientColor = Color(
      0xFFF8C8DC,
    ); // A gentle, standard pink
    const Color darkTextColor = Color(
      0xFF8B4568,
    ); // A deep, warm magenta for contrast

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topGradientColor, bottomGradientColor],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background shapes - white blobs work great with any color
            _buildBlob(
              color: const Color.fromRGBO(
                255,
                255,
                255,
                0.25,
              ), // Made slightly more opaque
              top: -150,
              left: -100,
              radius: 250,
            ),
            _buildBlob(
              color: const Color.fromRGBO(
                255,
                255,
                255,
                0.25,
              ), // Made slightly more opaque
              bottom: -180,
              right: -100,
              radius: 280,
            ),

            // Main content with fade-in animation
            SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _opacity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The illustration
                      Image.asset(
                        'assets/welcome_illustration.png',
                        height: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.people,
                            size: 200,
                            color: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      // App Name
                      Text(
                        'KAMPUS KONNECT',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline or description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Your one-stop destination to Connect, Collaborate, and Thrive on campus.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: darkTextColor.withAlpha(
                              (255 * 0.8).round(),
                            ), // 80% opacity
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the decorative blobs
  Widget _buildBlob({
    required Color color,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double radius,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        height: radius,
        width: radius,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
