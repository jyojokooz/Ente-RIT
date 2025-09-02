// lib/screens/lost_and_found_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/lost_found_item_card.dart'; // The new card widget
import 'create_lost_found_post_screen.dart';
import 'lost_found_detail_screen.dart';
import 'resolved_items_screen.dart';

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
        children: [
          // Custom Tab Switcher
          _buildTabSwitcher(),

          // List of Items
          Expanded(child: _buildItemsList()),
        ],
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
        onTap: () => setState(() => _selectedStatus = status),
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

  Widget _buildItemsList() {
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
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.2, // Adjust this ratio for card height
            mainAxisSpacing: 20,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemDoc = items[index];
            final item = itemDoc.data() as Map<String, dynamic>;

            return LostFoundItemCard(
              title: item['title'] ?? 'No Title',
              status: item['status'] ?? 'N/A',
              location: item['location'] ?? 'N/A',
              imageUrl: item['imageUrl'],
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LostFoundDetailScreen(itemDoc: itemDoc),
                    ),
                  ),
            );
          },
        );
      },
    );
  }
}
