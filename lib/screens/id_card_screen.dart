// ===============================
// FILE NAME: id_card_screen.dart
// FILE PATH: lib/screens/id_card_screen.dart
// ===============================

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flip_card/flip_card.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({super.key});

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    // Listen to gyroscope events to create the tilt effect
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          // Adjust sensitivity by multiplying event data
          _tiltY += event.y * 0.02;
          _tiltX += event.x * 0.02;
          // Clamp the values to prevent extreme tilting
          _tiltX = _tiltX.clamp(-0.2, 0.2);
          _tiltY = _tiltY.clamp(-0.2, 0.2);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Virtual ID',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
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
                child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'User data not found',
                  style: TextStyle(color: textColor),
                ),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated 3D Tilt Effect
                  Transform(
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateX(_tiltX)
                          ..rotateY(_tiltY),
                    alignment: FractionalOffset.center,
                    child: FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      speed: 600,
                      onFlipDone: (isFront) => HapticFeedback.selectionClick(),
                      front: _buildCardFront(userData, isDark),
                      back: _buildCardBack(userData, isDark),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: isDark ? Colors.white24 : Colors.black12,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Tap card to flip",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white30 : Colors.black26,
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

  Widget _buildCardFront(Map<String, dynamic> userData, bool isDark) {
    final displayName = userData['displayName'] ?? 'Student Name';
    final department = userData['department'] ?? 'General Engineering';
    final studentId = userData['studentId'] ?? 'RIT-000000';
    final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
    final validThru =
        (userData['validThru'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 365 * 4));

    return Container(
      width: 340,
      height: 540,
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF252528)
                : Colors.black, // Front is always dark
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              51,
            ), // FIX: Replaced .withOpacity(0.2)
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Watermark Background
            Positioned(
              right: -40,
              top: -40,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.shield, size: 250, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top Header
                  Row(
                    children: [
                      Image.asset(
                        'assets/app_icon.png',
                        height: 40,
                        errorBuilder:
                            (c, e, s) => const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 40,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ente RIT",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "STUDENT ID",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Profile Photo with Gradient Ring
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFB165FF), Color(0xFFFF4B72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252528) : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey[800],
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
                  const SizedBox(height: 24),

                  // Name and Verified Badge
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Department Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ), // FIX: Replaced .withOpacity(0.1)
                    child: Text(
                      department,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Info Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCol("ID Number", studentId),
                      _buildInfoCol(
                        "Valid Thru",
                        DateFormat('MM/yy').format(validThru),
                        crossAxisAlignment: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> userData, bool isDark) {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final studentId = userData['studentId'] ?? '000000';
    final qrData = 'https://enterit.web.app/verify/$userUid';

    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;

    return Container(
      width: 340,
      height: 540,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ), // FIX: Replaced .withOpacity(0.1)
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            height: 50,
            width: double.infinity,
            color: isDark ? const Color(0xFF161618) : Colors.black,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 170.0,
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
          const SizedBox(height: 12),
          Text(
            "Scan to verify identity",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            height: 50,
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: studentId,
              drawText: false,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            studentId,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              "This card is the property of RIT Kottayam. If found, please return to the administrative office.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCol(
    String label,
    String value, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
