import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  Future<void> _toggleUserRole(String userId, String currentRole) async {
    final newRole = currentRole == 'driver' ? 'user' : 'driver';
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
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final bool isAdmin = userData['isAdmin'] ?? false;
              final String role = userData['role'] ?? 'user';
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
                        backgroundImage:
                            userData['profilePhotoUrl'] != null &&
                                    userData['profilePhotoUrl'].isNotEmpty
                                ? NetworkImage(userData['profilePhotoUrl'])
                                : null,
                        child:
                            userData['profilePhotoUrl'] == null ||
                                    userData['profilePhotoUrl'].isEmpty
                                ? const Icon(Icons.person)
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
                              ),
                            ),
                            Text(
                              userData['email'] ?? 'No Email',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        const Chip(
                          label: Text('Admin'),
                          backgroundColor: Colors.yellow,
                        ),
                      if (role == 'driver')
                        const Chip(
                          label: Text('Driver'),
                          backgroundColor: Colors.cyan,
                        ),
                      if (!isAdmin)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle_role') {
                              _toggleUserRole(users[index].id, role);
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
