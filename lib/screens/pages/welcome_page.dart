import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the reusable button widget. Ensure the path is correct for your project structure.
import '../../widgets/custom_auth_button.dart';

class WelcomePage extends StatelessWidget {
  // These callbacks are required to trigger navigation in the parent AuthScreen.
  final VoidCallback onLoginTapped;
  final VoidCallback onSignupTapped;

  const WelcomePage({
    super.key,
    required this.onLoginTapped,
    required this.onSignupTapped,
  });

  @override
  Widget build(BuildContext context) {
    // These colors are for the content elements, like icons and text.
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;

    // NO SCAFFOLD OR APPBAR HERE.
    // The Scaffold and background color are provided by the parent AuthScreen.
    // This widget only returns the content to be displayed.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Image
            Image.asset(
              'assets/kampus_konnect_logo_wide.png',
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon in case the image fails to load.
                return const Icon(
                  Icons.connect_without_contact,
                  size: 200,
                  color: primaryAccentColor,
                );
              },
            ),
            const SizedBox(height: 40),

            // Title Text
            Text(
              "Welcome to KAMPUS KONNECT!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle Text
            Text(
              "Log in or create an account to get started.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),

            // Log In Button (Secondary Style)
            CustomAuthButton(
              onPressed:
                  onLoginTapped, // Triggers the page change in AuthScreen
              text: "Log In",
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 20),

            // Create Account Button (Primary Style)
            CustomAuthButton(
              onPressed:
                  onSignupTapped, // Triggers the page change in AuthScreen
              text: "Create an Account",
              // No colors passed, so it uses the default yellow/black style
            ),
          ],
        ),
      ),
    );
  }
}
