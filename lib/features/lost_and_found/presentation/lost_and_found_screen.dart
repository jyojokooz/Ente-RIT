// ===============================
// FILE NAME: lost_and_found_screen.dart
// FILE PATH: lib/screens/lost_and_found_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/features/lost_and_found/presentation/widgets/lost_found_item_card.dart';
import 'package:my_project/features/lost_and_found/presentation/create_lost_found_post_screen.dart';
import 'package:my_project/features/lost_and_found/presentation/lost_found_detail_screen.dart';
import 'package:my_project/features/lost_and_found/presentation/resolved_items_screen.dart';
import 'package:my_project/features/lost_and_found/presentation/edit_lost_found_post_screen.dart';

class LostAndFoundScreen extends StatefulWidget {
  const LostAndFoundScreen({super.key});

  @override
  State<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _LostAndFoundScreenState extends State<LostAndFoundScreen> {
  String _selectedStatus = 'lost';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Lost & Found',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: textColor, size: 26),
            tooltip: 'Resolved History',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const ResolvedItemsScreen(),
                  ),
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildTabSwitcher(isDark),
          Expanded(child: _buildItemsList(isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateLostFoundPostScreen(),
              ),
            ),
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          "Report",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(bool isDark) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(
            'lost',
            'Lost Items',
            activeColor,
            inactiveColor,
            isDark,
          ),
          _buildTabItem(
            'found',
            'Found Items',
            activeColor,
            inactiveColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    String status,
    String label,
    Color activeColor,
    Color inactiveColor,
    bool isDark,
  ) {
    final isSelected = _selectedStatus == status;

    // Dynamic gradient based on tab
    final gradient =
        isSelected
            ? LinearGradient(
              colors:
                  status == 'lost'
                      ? const [Color(0xFFFF9A44), Color(0xFFFF3E8E)]
                      : const [Color(0xFF00C6FB), Color(0xFF005BEA)],
            )
            : null;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : inactiveColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(bool isDark) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final query = FirebaseFirestore.instance
        .collection('lost_and_found')
        .where('status', isEqualTo: _selectedStatus)
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white : Colors.black,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading items.",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedStatus.toUpperCase()} items reported.',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!.docs;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemDoc = items[index];
            final item = itemDoc.data() as Map<String, dynamic>;
            final bool isOwner =
                currentUser != null && currentUser.uid == item['userId'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: LostFoundItemCard(
                title: item['title'] ?? 'No Title',
                status: item['status'] ?? 'N/A',
                location: item['location'] ?? 'N/A',
                userName: item['userName'] ?? 'Anonymous',
                imageUrl: item['imageUrl'],
                isOwner: isOwner,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LostFoundDetailScreen(itemDoc: itemDoc),
                      ),
                    ),
                onEdit:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditLostFoundPostScreen(itemDoc: itemDoc),
                      ),
                    ),
                onDelete:
                    () => _showDeleteConfirmation(context, itemDoc.id, isDark),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String itemId,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Delete Post?',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to permanently delete this report?',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('lost_and_found')
                      .doc(itemId)
                      .delete();
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }
}
