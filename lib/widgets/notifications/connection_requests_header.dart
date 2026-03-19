// ===============================
// FILE NAME: connection_requests_header.dart
// FILE PATH: lib/widgets/notifications/connection_requests_header.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/requests_screen.dart';

class ConnectionRequestsHeader extends StatelessWidget {
  final User currentUser;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const ConnectionRequestsHeader({
    super.key,
    required this.currentUser,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
      builder: (context, userSnapshot) {
        // We only care about received requests here now
        if (!userSnapshot.hasData) return const SizedBox.shrink();

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> receivedRequests =
            userData['receivedRequests'] ?? [];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connection Requests",
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (receivedRequests.isEmpty)
                // Empty State for Requests
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_disabled_rounded,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "No pending requests",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Active Requests Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C6FB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Review Requests",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                "You have ${receivedRequests.length} new request${receivedRequests.length > 1 ? 's' : ''}",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF3E8E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
