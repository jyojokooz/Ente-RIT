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
  @override
  void initState() {
    super.initState();
    // Start a timer that will run after 3 seconds
    Timer(const Duration(seconds: 3), _navigateUser);
  }

  /// Check the user's authentication status and navigate accordingly.
  void _navigateUser() {
    // Use pushReplacementNamed so the user can't go back to the splash screen
    if (FirebaseAuth.instance.currentUser != null) {
      // User is logged in, go to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User is not logged in, go to the welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8BFE7), // A pleasant theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your App Logo
            const Icon(Icons.lock_open_rounded, size: 120, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'KAMPUS KONNECT!', // Your App Name
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
