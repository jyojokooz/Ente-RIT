// ===============================
// FILE NAME: connection_requests_header.dart
// FILE PATH: lib/widgets/notifications/connection_requests_header.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/requests_screen.dart';

class ConnectionRequestsHeader extends StatefulWidget {
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
  State<ConnectionRequestsHeader> createState() =>
      _ConnectionRequestsHeaderState();
}

class _ConnectionRequestsHeaderState extends State<ConnectionRequestsHeader> {
  List<dynamic> _validRequests = [];
  bool _isCheckingGhosts = false;

  // This function checks if the requests are actually valid (the users still exist)
  Future<void> _validateAndHealRequests(List<dynamic> rawRequests) async {
    if (rawRequests.isEmpty) {
      if (mounted) setState(() => _validRequests = []);
      return;
    }

    if (_isCheckingGhosts) return; // Prevent spamming
    _isCheckingGhosts = true;

    List<dynamic> validatedList = [];
    bool hasGhostUsers = false;

    for (String reqId in rawRequests) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(reqId)
                .get();
        if (doc.exists) {
          validatedList.add(reqId);
        } else {
          hasGhostUsers = true;
        }
      } catch (e) {
        // Assume valid on network error to be safe
        validatedList.add(reqId);
      }
    }

    if (mounted) {
      setState(() {
        _validRequests = validatedList;
        _isCheckingGhosts = false;
      });
    }

    // Auto-heal the database if ghost users were found
    if (hasGhostUsers) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .update({'receivedRequests': validatedList});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser.uid)
              .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> rawRequests = userData['receivedRequests'] ?? [];

        // Trigger the ghost check without blocking the UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rawRequests.length != _validRequests.length &&
              !_isCheckingGhosts) {
            _validateAndHealRequests(rawRequests);
          }
        });

        // Use the validated list if we have checked, otherwise fallback to raw initially
        final displayRequests =
            _isCheckingGhosts ? _validRequests : rawRequests;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connection Requests",
                style: GoogleFonts.poppins(
                  color: widget.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (displayRequests.isEmpty)
                // Empty State for Requests
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          widget.isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_disabled_rounded,
                        color: widget.isDark ? Colors.white30 : Colors.black38,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "No requests came.",
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDark ? Colors.white54 : Colors.black54,
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
                      color: widget.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!widget.isDark)
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
                                  color: widget.textColor,
                                ),
                              ),
                              Text(
                                "You have ${displayRequests.length} new request${displayRequests.length > 1 ? 's' : ''}",
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
              const SizedBox(height: 16),
              Divider(
                color: widget.isDark ? Colors.white10 : Colors.black12,
                height: 1,
              ),
              const SizedBox(height: 16),
              Text(
                "Recent Activity",
                style: GoogleFonts.poppins(
                  color: widget.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
