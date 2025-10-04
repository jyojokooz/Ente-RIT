import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  // --- NEW: Define the list of assignable roles ---
  final List<String> _assignableRoles = [
    'student',
    'teacher',
    'driver',
    'cafeteria_admin',
    'admin',
  ];

  /// Sets a user's role to the specified new role.
  Future<void> _changeUserRole(String userId, String newRole) async {
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
      // We also handle the isAdmin flag for convenience.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'isAdmin':
            newRole == 'admin', // Set isAdmin to true if the role is admin
      });
    }
  }

  /// --- NEW: Helper widget to display a role chip ---
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
        return const SizedBox.shrink(); // Don't show a chip for default 'user'
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
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8), // Reduced padding
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'student';
              final profilePhotoUrl = userData['profilePhotoUrl'] ?? '';
              final hasImage = profilePhotoUrl.isNotEmpty;

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
                              userData['displayName'] ?? 'No Name',
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
                      // Display chip for the user's role
                      _buildRoleChip(role),

                      // Role management menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (String newRole) {
                          _changeUserRole(userDoc.id, newRole);
                        },
                        itemBuilder:
                            (ctx) =>
                                _assignableRoles
                                    .map(
                                      (roleToAssign) => PopupMenuItem<String>(
                                        value: roleToAssign,
                                        child: Text(
                                          'Set as ${roleToAssign.replaceAll('_', ' ')}',
                                        ),
                                      ),
                                    )
                                    .toList(),
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
