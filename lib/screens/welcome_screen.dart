import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- COLOR UPDATES ---
    // Taking the theme directly from the splash screen
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color buttonTextColor = Colors.black;

    return Scaffold(
      backgroundColor: screenBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The logo image
              Image.asset(
                'assets/kampus_konnect_logo_wide.png',
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon now uses the new accent color
                  return const Icon(
                    Icons.connect_without_contact,
                    size: 200,
                    color: primaryAccentColor,
                  );
                },
              ),
              const SizedBox(height: 40),

              // Title text
              Text(
                "Welcome to KAMPUS KONNECT!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor, // Changed to white
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle text
              Text(
                "Log in or create an account to get started.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70, // Kept for good contrast
                ),
              ),
              const SizedBox(height: 50),

              // --- BUTTON UPDATES ---

              // Log In Button (Secondary Action) - Now a white button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // A clean white button
                  foregroundColor: buttonTextColor, // With black text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Log In",
                  style: GoogleFonts.poppins(
                    color: buttonTextColor, // Explicitly set text color
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Create Account Button (Primary Action) - Now a yellow button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccentColor, // The vibrant yellow
                  foregroundColor: buttonTextColor, // With black text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Create an Account",
                  style: GoogleFonts.poppins(
                    color: buttonTextColor, // Explicitly set text color
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
