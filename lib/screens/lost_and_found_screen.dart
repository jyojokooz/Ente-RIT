import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all the necessary widgets and screens.
import '../widgets/lost_found_item_card.dart';
import 'create_lost_found_post_screen.dart';
import 'lost_found_detail_screen.dart';
import 'resolved_items_screen.dart';
import 'edit_lost_found_post_screen.dart'; // Import the new edit screen

/// The main screen for the Lost & Found feature. It displays a list of
/// active items and allows users to switch between "Lost" and "Found" categories.
class LostAndFoundScreen extends StatefulWidget {
  const LostAndFoundScreen({super.key});

  @override
  State<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _LostAndFoundScreenState extends State<LostAndFoundScreen> {
  String _selectedStatus = 'lost';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lost & Found',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, size: 28),
            tooltip: 'Resolved Items History',
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
        children: [_buildTabSwitcher(), Expanded(child: _buildItemsList())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateLostFoundPostScreen(),
              ),
            ),
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  /// Builds the custom, animated tab switcher widget.
  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabItem('lost', 'Lost Items'),
          _buildTabItem('found', 'Found Items'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the grid of items fetched from Firestore and handles owner-specific actions.
  Widget _buildItemsList() {
    // Get the current user to check for item ownership.
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellow),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $_selectedStatus items reported yet.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        final items = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.2,
            mainAxisSpacing: 20,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemDoc = items[index];
            final item = itemDoc.data() as Map<String, dynamic>;

            // Check if the current user is the owner of this specific item.
            final bool isOwner =
                currentUser != null && currentUser.uid == item['userId'];

            return LostFoundItemCard(
              title: item['title'] ?? 'No Title',
              status: item['status'] ?? 'N/A',
              location: item['location'] ?? 'N/A',
              userName: item['userName'] ?? 'Anonymous',
              imageUrl: item['imageUrl'],
              isOwner: isOwner, // Pass the ownership status to the card.
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LostFoundDetailScreen(itemDoc: itemDoc),
                    ),
                  ),
              // Define the callback for the "Edit" action.
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLostFoundPostScreen(itemDoc: itemDoc),
                  ),
                );
              },
              // Define the callback for the "Delete" action.
              onDelete: () => _showDeleteConfirmation(context, itemDoc.id),
            );
          },
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting an item from Firestore.
  void _showDeleteConfirmation(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to permanently delete this post?',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () {
                  // Delete the document from Firestore and close the dialog.
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
