import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flip_card/flip_card.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For haptic feedback

class IdCardScreen extends StatelessWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    // Set status bar color to match the app bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xff121212), // Dark background
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Digital ID Card',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Color(0xfffacc15));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'Could not load user data.\nPlease complete your profile first.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return FlipCard(
              onFlipDone: (isFront) => HapticFeedback.lightImpact(),
              front: _buildCardFront(userData, context),
              back: _buildCardBack(userData),
            );
          },
        ),
      ),
    );
  }

  /// Builds the front side of the ID card.
  Widget _buildCardFront(Map<String, dynamic> userData, BuildContext context) {
    // --- Data Extraction with Fallbacks ---
    final displayName = userData['displayName'] ?? 'Your Name';
    final department = userData['department'] ?? 'Your Department';
    final studentId = userData['studentId'] ?? '000000000';
    final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
    final joinedAt = (userData['joinedAt'] as Timestamp?)?.toDate();
    final validThru =
        (userData['validThru'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 365 * 4));

    // --- Formatted Data ---
    final formattedStudentId =
        studentId
            .replaceAllMapped(RegExp(r".{3}"), (match) => "${match.group(0)} ")
            .trim();

    return Container(
      width: 330,
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xff1f1f1f), Color(0xff2d2d2d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128), // <-- CORRECTED HERE
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                Image.asset(
                  'assets/logo_placeholder.png', // Replace with your logo
                  height: 40,
                  errorBuilder:
                      (ctx, err, st) => const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      ),
                ),
                const SizedBox(width: 10),
                Text(
                  'UNIVERSITY',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            // --- Profile Picture and Info ---
            Row(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xfffacc15),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        profilePhotoUrl.isNotEmpty
                            ? NetworkImage(profilePhotoUrl)
                            : null,
                    child:
                        profilePhotoUrl.isEmpty
                            ? const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfffacc15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          department,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // --- ID and Dates ---
            _buildInfoField('STUDENT ID', formattedStudentId),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoField(
                  'MEMBER SINCE',
                  joinedAt != null
                      ? DateFormat('MM/yyyy').format(joinedAt)
                      : 'N/A',
                ),
                _buildInfoField(
                  'VALID THRU',
                  DateFormat('MM/yy').format(validThru),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Builds the back side of the ID card.
  Widget _buildCardBack(Map<String, dynamic> userData) {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final studentId = userData['studentId'] ?? 'NOT-SET';

    // IMPORTANT: This URL should point to a web page you create.
    // This page will display the user's public profile.
    final qrData = 'https://fir-auth-bfed9.web.app/profile/$userUid';

    return Container(
      width: 330,
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xff2d2d2d), Color(0xff1f1f1f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          // --- Magnetic Stripe ---
          Container(height: 50, color: Colors.black),
          const SizedBox(height: 40),
          // --- QR Code ---
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 150.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          // --- Barcode ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: studentId,
                drawText: false,
                color: Colors.black,
                height: 50,
              ),
            ),
          ),
          const Spacer(),
          // --- Disclaimer ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'This card is for official campus use only. If found, please return it to the administration office or scan the QR code for contact information.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget to create styled info fields to reduce code duplication.
  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withAlpha(153), // <-- CORRECTED HERE
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
