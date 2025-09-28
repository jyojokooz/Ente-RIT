import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  /// Toggles a user's role between 'user' and 'driver'.
  Future<void> _toggleUserRole(String userId, String currentRole) async {
    // Determine the new role based on the current role.
    final newRole = currentRole == 'driver' ? 'user' : 'driver';

    // Show a confirmation dialog to prevent accidental changes.
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
        false; // Default to false if the dialog is dismissed.

    if (confirmChange) {
      // If confirmed, update the user's document in Firestore.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
    }
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
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final bool isAdmin = userData['isAdmin'] ?? false;
              final String role = userData['role'] ?? 'user';
              final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
              final bool hasImage = profilePhotoUrl.isNotEmpty;

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['displayName'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              userData['email'] ?? 'No Email',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Display chips for special roles
                      if (isAdmin)
                        const Chip(
                          label: Text('Admin'),
                          backgroundColor: Colors.yellow,
                          labelStyle: TextStyle(color: Colors.black),
                        ),

                      if (role == 'driver')
                        const Chip(
                          label: Text('Driver'),
                          backgroundColor: Colors.cyan,
                        ),

                      // Show role management menu for non-admins
                      if (!isAdmin)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle_role') {
                              _toggleUserRole(userDoc.id, role);
                            }
                          },
                          itemBuilder:
                              (ctx) => [
                                PopupMenuItem(
                                  value: 'toggle_role',
                                  child: Text(
                                    role == 'driver'
                                        ? 'Set as User'
                                        : 'Set as Driver',
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
