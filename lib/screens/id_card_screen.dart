// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flip_card/flip_card.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class IdCardScreen extends StatelessWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    // Set status bar styles
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-style light grey
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Virtual ID',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('User data not found'));
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlipCard(
                    direction: FlipDirection.HORIZONTAL,
                    speed: 600,
                    onFlipDone: (isFront) => HapticFeedback.selectionClick(),
                    front: _buildCardFront(userData),
                    back: _buildCardBack(userData),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Tap card to flip for QR Code",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? 'Student Name';
    final department = userData['department'] ?? 'General Engineering';
    final studentId = userData['studentId'] ?? 'RIT-000000';
    final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
    final dob = userData['dob']; // Assuming you might have this, or fallback
    final validThru =
        (userData['validThru'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 365 * 4));

    return Container(
      width: 340,
      height: 540,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Watermark Background
            Positioned(
              right: -40,
              bottom: -40,
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/app_icon.png', // Ensure you have an asset here
                  height: 300,
                  width: 300,
                  errorBuilder:
                      (c, e, s) => const Icon(Icons.school, size: 300),
                ),
              ),
            ),

            // 2. Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A), // Dark elegant header
                ),
                child: Stack(
                  children: [
                    // Decorative Curves
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "RIT KOTTAYAM",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "RAJIV GANDHI INSTITUTE OF TECHNOLOGY",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Main Content
            Padding(
              padding: const EdgeInsets.only(
                top: 70.0,
              ), // Push down below header
              child: Column(
                children: [
                  // Profile Photo Container
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            profilePhotoUrl.isNotEmpty
                                ? NetworkImage(profilePhotoUrl)
                                : null,
                        child:
                            profilePhotoUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name and Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),

                  // Role Badge
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "STUDENT",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Info Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        _buildInfoRow("ID Number", studentId),
                        const Divider(height: 24, color: Colors.black12),
                        _buildInfoRow("Department", department),
                        const Divider(height: 24, color: Colors.black12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                "Valid Thru",
                                DateFormat('MM/yy').format(validThru),
                              ),
                            ),
                            Expanded(
                              child: _buildInfoRow(
                                "DOB",
                                dob != null
                                    ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format((dob as Timestamp).toDate())
                                    : "N/A",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Color Strip
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow, Colors.black],
                        stops: [0.3, 0.3],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> userData) {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final studentId = userData['studentId'] ?? '000000';
    final qrData = 'https://enterit.web.app/verify/$userUid';

    return Container(
      width: 340,
      height: 540,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Magnetic Stripe
          Container(
            height: 50,
            width: double.infinity,
            color: const Color(0xFF2D2D2D),
          ),

          const Spacer(),

          // QR Code Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180.0,
              gapless: false,
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            "Scan to verify identity",
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
          ),

          const Spacer(),

          // Barcode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: SizedBox(
              height: 50,
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: studentId,
                drawText: false,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            studentId,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              letterSpacing: 2,
              color: Colors.black54,
            ),
          ),

          const Spacer(),

          // Footer Text
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "This card is the property of RIT Kottayam. If found, please return to the administrative office.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
