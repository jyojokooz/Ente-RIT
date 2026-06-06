import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Terms & Privacy",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Terms of Service & Privacy Policy",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Last updated: October 2023",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildTextSection(
                "1. Introduction",
                "Welcome to Ente RIT. By using our application, you agree to these terms. Please read them carefully. The app is designed exclusively for the students, faculty, and staff of Rajiv Gandhi Institute of Technology (RIT), Kottayam.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "2. User Data & Privacy",
                "We respect your privacy. Your email, student ID, and profile information are stored securely on our servers to verify your identity within the campus network. We do not sell your personal data to third parties. You have the right to delete your account and all associated data at any time via the Settings menu.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "3. Community Guidelines",
                "Ente RIT relies on a safe, respectful environment. Harassment, bullying, hate speech, and the posting of explicit or inappropriate content are strictly prohibited. Violations will result in immediate account termination. Use the 'Report' feature to notify admins of any concerning behavior.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "4. Intellectual Property",
                "You retain ownership of the content you post. However, by posting, you grant Ente RIT a license to display that content within the application. Do not post copyrighted material without permission.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "5. Limitation of Liability",
                "Ente RIT is provided 'as is'. We do not guarantee that the app will be error-free or uninterrupted. We are not responsible for user-generated content or interactions between users.",
                textColor,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection(
    String title,
    String content,
    Color textColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
