// lib/screens/resolved_items_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/lost_found_item_card.dart';
import 'lost_found_detail_screen.dart';

class ResolvedItemsScreen extends StatelessWidget {
  const ResolvedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Resolved History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No items have been resolved yet.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final resolvedItems = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.2,
              mainAxisSpacing: 20,
            ),
            itemCount: resolvedItems.length,
            itemBuilder: (context, index) {
              final itemDoc = resolvedItems[index];
              final item = itemDoc.data() as Map<String, dynamic>;

              return Opacity(
                opacity: 0.7,
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
                  // --- FIX: Pass empty functions for required callbacks ---
                  onEdit: () {},
                  onDelete: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
