import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({super.key});

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
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
              return const Text('Could not load user data.');
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            // Extract data with fallbacks
            final displayName = userData['displayName'] ?? 'No Name';
            final username = userData['username'] ?? 'No Username';
            final department = userData['department'] ?? 'No Department';
            final studentId = userData['studentId'] ?? 'N/A';
            final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';

            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.yellow, width: 2),
                boxShadow: [
                  BoxShadow(
                    // --- FIX APPLIED HERE ---
                    color: Colors.yellow.withAlpha(51), // 0.2 opacity
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.yellow,
                    child: CircleAvatar(
                      radius: 47,
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
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    department,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.yellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 40),
                  Text(
                    'STUDENT ID',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    studentId,
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: user.uid,
                      version: QrVersions.auto,
                      size: 120.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
