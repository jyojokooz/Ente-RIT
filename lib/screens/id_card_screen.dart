import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flip_card/flip_card.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';

class IdCardScreen extends StatelessWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Digital ID Card', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
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
              return const CircularProgressIndicator(color: Colors.yellow);
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'Could not load user data.\nPlease complete your profile first.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              );
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return FlipCard(
              front: _buildCardFront(userData),
              back: _buildCardBack(userData),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? 'No Name';
    final department = userData['department'] ?? 'No Department';
    final studentId = userData['studentId'] ?? 'N/A';
    final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
    final joinedAt = (userData['joinedAt'] as Timestamp?)?.toDate();

    final formattedStudentId =
        studentId
            .replaceAllMapped(RegExp(r".{3}"), (match) => "${match.group(0)} ")
            .trim();

    return Container(
      width: 320,
      height: 500,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(75),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/logo_placeholder.png',
            height: 50,
            errorBuilder:
                (ctx, err, st) =>
                    const Icon(Icons.school, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundImage:
                  profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null,
              child:
                  profilePhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            displayName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            department,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.yellow,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STUDENT ID',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    formattedStudentId,
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MEMBER SINCE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    joinedAt != null
                        ? DateFormat('MM/yyyy').format(joinedAt)
                        : 'N/A',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> userData) {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final studentId = userData['studentId'] ?? 'N/A';

    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Container(height: 50, color: Colors.black),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(data: userUid, version: QrVersions.auto),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.white,
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: studentId,
                drawText: false,
                color: Colors.black,
                height: 60,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'This card is for official campus use only. If found, please return to the administration office.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
