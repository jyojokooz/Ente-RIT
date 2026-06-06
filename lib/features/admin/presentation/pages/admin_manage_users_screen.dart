import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final List<String> _assignableRoles = [
    'student',
    'teacher',
    'driver',
    'cafeteria_admin',
    'admin',
  ];

  Future<void> _changeUserRole(String userId, String newRole) async {
    final bool confirmChange =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.grey.shade800,
                title: const Text('Change Role?'),
                content: Text(
                  'Do you want to change this user\'s role to "$newRole"?',
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
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'isAdmin': newRole == 'admin',
      });
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.grey.shade800,
                title: const Text(
                  'Delete User?',
                  style: TextStyle(color: Colors.red),
                ),
                content: Text(
                  'Are you sure you want to permanently delete "$userName"?\n\nThis will remove their profile immediately.',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        final firestore = FirebaseFirestore.instance;

        // --- THE FIX: GLOBAL DATABASE CLEANUP ---
        // 1. Remove from all connections
        final connectionsQuery =
            await firestore
                .collection('users')
                .where('connections', arrayContains: userId)
                .get();
        for (var doc in connectionsQuery.docs) {
          doc.reference.update({
            'connections': FieldValue.arrayRemove([userId]),
          });
        }

        // 2. Remove from all sentRequests
        final sentQuery =
            await firestore
                .collection('users')
                .where('sentRequests', arrayContains: userId)
                .get();
        for (var doc in sentQuery.docs) {
          doc.reference.update({
            'sentRequests': FieldValue.arrayRemove([userId]),
          });
        }

        // 3. Remove from all receivedRequests
        final receivedQuery =
            await firestore
                .collection('users')
                .where('receivedRequests', arrayContains: userId)
                .get();
        for (var doc in receivedQuery.docs) {
          doc.reference.update({
            'receivedRequests': FieldValue.arrayRemove([userId]),
          });
        }

        // Finally, delete the actual user profile document
        await firestore.collection('users').doc(userId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile deleted globally.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
        }
      }
    }
  }

  Widget _buildRoleChip(String role) {
    Color chipColor;
    String label;

    switch (role) {
      case 'admin':
        chipColor = Colors.yellow;
        label = 'Admin';
        break;
      case 'driver':
        chipColor = Colors.cyan;
        label = 'Driver';
        break;
      case 'teacher':
        chipColor = Colors.green;
        label = 'Teacher';
        break;
      case 'cafeteria_admin':
        chipColor = Colors.orange;
        label = 'Cafeteria';
        break;
      case 'student':
        chipColor = Colors.blue;
        label = 'Student';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: chipColor,
        labelStyle: TextStyle(
          color: chipColor == Colors.yellow ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .orderBy('displayName')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'student';
              final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
              final hasImage = profilePhotoUrl.isNotEmpty;
              final displayName = userData['displayName'] ?? 'No Name';

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade700,
                        backgroundImage:
                            hasImage ? NetworkImage(profilePhotoUrl) : null,
                        child:
                            !hasImage
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white60,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userData['email'] ?? 'No Email',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildRoleChip(role),

                      // --- FIX: Using PopupMenuEntry<String> ---
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (String value) {
                          if (value == 'delete_user_action') {
                            _deleteUser(userDoc.id, displayName);
                          } else {
                            _changeUserRole(userDoc.id, value);
                          }
                        },
                        itemBuilder: (ctx) {
                          // 1. Create a generic list of Entries, NOT specific Items
                          List<PopupMenuEntry<String>> items = [];

                          // 2. Add Role Options
                          for (var roleToAssign in _assignableRoles) {
                            items.add(
                              PopupMenuItem<String>(
                                value: roleToAssign,
                                child: Text(
                                  'Set as ${roleToAssign.replaceAll('_', ' ')}',
                                ),
                              ),
                            );
                          }

                          // 3. Add Divider
                          items.add(const PopupMenuDivider());

                          // 4. Add Delete Option
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'delete_user_action',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete User',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          return items;
                        },
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
