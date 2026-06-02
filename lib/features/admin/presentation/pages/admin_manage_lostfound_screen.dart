// ===============================
// FILE NAME: admin_manage_lostfound_screen.dart
// FILE PATH: lib/screens/admin/admin_manage_lostfound_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminManageLostFoundScreen extends StatefulWidget {
  const AdminManageLostFoundScreen({super.key});

  @override
  State<AdminManageLostFoundScreen> createState() =>
      _AdminManageLostFoundScreenState();
}

class _AdminManageLostFoundScreenState
    extends State<AdminManageLostFoundScreen> {
  Future<void> _toggleResolvedStatus(String itemId, bool currentStatus) async {
    final bool confirmChange =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF252528),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  currentStatus ? 'Re-open Item?' : 'Resolve Item?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  currentStatus
                      ? 'Mark this item as active again?'
                      : 'Mark this item as resolved?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmChange) {
      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(itemId)
          .update({'isResolved': !currentStatus});
    }
  }

  Future<void> _deleteLostAndFoundItem(String itemId) async {
    final bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF252528),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Delete Item?',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Are you sure you want to permanently delete this item?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(itemId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Manage Lost & Found',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('lost_and_found')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C6FB)),
            );
          }
          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return Center(
              child: Text(
                "No items reported.",
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemData = items[index].data() as Map<String, dynamic>;
              final bool isResolved = itemData['isResolved'] ?? false;
              final bool hasImage =
                  itemData['imageUrl'] != null &&
                  itemData['imageUrl'].isNotEmpty;

              return Card(
                color: const Color(0xFF161618),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white10),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        hasImage
                            ? CachedNetworkImage(
                              imageUrl: itemData['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 50,
                              height: 50,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.find_in_page,
                                color: Colors.white54,
                              ),
                            ),
                  ),
                  title: Text(
                    itemData['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'by ${itemData['userName'] ?? '...'}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isResolved
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isResolved ? 'Resolved' : 'Active',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isResolved
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF252528),
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'toggle') {
                        _toggleResolvedStatus(items[index].id, isResolved);
                      }
                      if (value == 'delete') {
                        _deleteLostAndFoundItem(items[index].id);
                      }
                    },
                    itemBuilder:
                        (ctx) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  isResolved
                                      ? Icons.replay
                                      : Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isResolved ? 'Mark Active' : 'Mark Resolved',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
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
