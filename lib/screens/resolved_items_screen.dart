// ===============================
// FILE NAME: resolved_items_screen.dart
// FILE PATH: lib/screens/resolved_items_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/lost_found_item_card.dart';
import 'lost_found_detail_screen.dart';

class ResolvedItemsScreen extends StatelessWidget {
  const ResolvedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Resolved History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('lost_and_found')
                .where('isResolved', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 60,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No resolved items yet.',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final resolvedItems = snapshot.data!.docs;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: resolvedItems.length,
            itemBuilder: (context, index) {
              final itemDoc = resolvedItems[index];
              final item = itemDoc.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Opacity(
                  opacity: 0.7, // Visual indicator that it's inactive
                  child: LostFoundItemCard(
                    title: item['title'] ?? 'No Title',
                    status: item['status'] ?? 'N/A',
                    location: item['location'] ?? 'N/A',
                    userName: item['userName'] ?? 'Anonymous',
                    imageUrl: item['imageUrl'],
                    isResolved: true,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => LostFoundDetailScreen(itemDoc: itemDoc),
                          ),
                        ),
                    onEdit: () {}, // Not editable when resolved
                    onDelete: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
