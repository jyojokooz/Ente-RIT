// lib/widgets/custom_auth_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isLoading;
  final Color? backgroundColor; // <-- NEW optional parameter
  final Color? foregroundColor; // <-- NEW optional parameter

  const CustomAuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.backgroundColor, // <-- NEW
    this.foregroundColor, // <-- NEW
  });

  @override
  Widget build(BuildContext context) {
    // Define default colors
    const Color defaultBackgroundColor = Colors.yellow;
    const Color defaultForegroundColor = Colors.black;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // Use the provided color, or fall back to the default
        backgroundColor: backgroundColor ?? defaultBackgroundColor,
        foregroundColor: foregroundColor ?? defaultForegroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child:
          isLoading
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  // Use the foreground color for the spinner
                  color: foregroundColor ?? defaultForegroundColor,
                  strokeWidth: 3,
                ),
              )
              : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }
}
