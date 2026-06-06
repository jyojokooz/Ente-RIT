import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final User user = FirebaseAuth.instance.currentUser!;

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
          "Personal Info",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF43E97B)),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final studentId = data['studentId'] ?? 'N/A';
          final role = data['role'] ?? 'Student';

          final creationTime = user.metadata.creationTime;
          final joinedDate =
              creationTime != null
                  ? DateFormat('MMMM d, yyyy').format(creationTime)
                  : 'Unknown';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "This information is private and is only used to secure your account and verify your identity within the campus network.",
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Container(
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
                  children: [
                    _buildInfoTile(
                      "Email Address",
                      user.email ?? "No Email",
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Student / Staff ID",
                      studentId,
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Account Role",
                      role.toString().toUpperCase(),
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Member Since",
                      joinedDate,
                      textColor,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    Color textColor,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}
