// lib/screens/admin/admin_manage_lostfound_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
                backgroundColor: Colors.grey.shade800,
                title: Text(currentStatus ? 'Re-open Item?' : 'Resolve Item?'),
                content: Text(
                  currentStatus
                      ? 'Do you want to mark this item as active again?'
                      : 'Are you sure you want to mark this item as resolved?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                backgroundColor: Colors.grey.shade800,
                title: const Text('Delete Item?'),
                content: const Text(
                  'Are you sure you want to permanently delete this item?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
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
        title: Text('Manage Lost & Found', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('lost_and_found')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // --- THIS IS THE FIX: Added curly braces {} ---
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- END OF FIX ---
          final items = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemData = items[index].data() as Map<String, dynamic>;
              final bool isResolved = itemData['isResolved'] ?? false;
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading:
                      itemData['imageUrl'] != null &&
                              itemData['imageUrl'].isNotEmpty
                          ? Image.network(
                            itemData['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image_not_supported),
                  title: Text(itemData['title'] ?? 'No Title'),
                  subtitle: Text('by ${itemData['userName'] ?? '...'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(isResolved ? 'Resolved' : 'Active'),
                        backgroundColor:
                            isResolved ? Colors.green : Colors.blueAccent,
                        labelStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle_resolved') {
                            _toggleResolvedStatus(items[index].id, isResolved);
                          }
                          if (value == 'delete') {
                            _deleteLostAndFoundItem(items[index].id);
                          }
                        },
                        itemBuilder:
                            (ctx) => [
                              PopupMenuItem(
                                value: 'toggle_resolved',
                                child: Text(
                                  isResolved
                                      ? 'Mark as Active'
                                      : 'Mark as Resolved',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
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
