import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> _acceptRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(requestFromId);

    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'connections': FieldValue.arrayUnion([requestFromId]),
    });
    batch.update(otherUserRef, {
      'connections': FieldValue.arrayUnion([_currentUser.uid]),
    });

    batch.update(currentUserRef, {
      'receivedRequests': FieldValue.arrayRemove([requestFromId]),
    });
    batch.update(otherUserRef, {
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
  }

  Future<void> _declineRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(requestFromId);

    final batch = FirebaseFirestore.instance.batch();
    batch.update(currentUserRef, {
      'receivedRequests': FieldValue.arrayRemove([requestFromId]),
    });
    batch.update(otherUserRef, {
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Connection Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> receivedRequests =
              userData['receivedRequests'] ?? [];

          if (receivedRequests.isEmpty) {
            return Center(
              child: Text(
                'No new requests.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final userId = receivedRequests[index];
              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  if (!userSnapshot.data!.exists) {
                    return const SizedBox.shrink(); // Don't show if user was deleted
                  }
                  final requestUserData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userImage = requestUserData['profilePhotoUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          userImage.isNotEmpty ? NetworkImage(userImage) : null,
                      child:
                          userImage.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(requestUserData['displayName'] ?? 'A User'),
                    subtitle: Text('@${requestUserData['username'] ?? ''}'),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: userId),
                          ),
                        ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () => _acceptRequest(userId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _declineRequest(userId),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
