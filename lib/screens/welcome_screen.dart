import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-using colors from your other screens for consistency
    const Color primaryColor = Color(0xFF5A4BDA);
    const Color screenBackgroundColor = Color(0xFFC8BFE7);

    return Scaffold(
      backgroundColor: screenBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- THIS IS THE UPDATED SECTION ---
              // Using your new, wide logo
              Image.asset(
                'assets/kampus_konnect_logo_wide.png',
                // We remove the height constraint so the image can display at its natural aspect ratio
                errorBuilder: (context, error, stackTrace) {
                  // Fallback in case the image fails to load
                  return const Icon(
                    Icons.connect_without_contact,
                    size: 200,
                    color: primaryColor,
                  );
                },
              ),
              const SizedBox(height: 40),

              Text(
                "Welcome to KAMPUS KONNECT!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Log in or create an account to get started.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 50),

              // Log In Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the Login Screen
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6E6FA),
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Log In",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Create Account Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the Signup Screen
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Create an Account",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
