// ===============================
// FILE NAME: requests_screen.dart
// FILE PATH: lib/screens/requests_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/profile_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> _acceptRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance.collection('users').doc(requestFromId);
    
    final batch = FirebaseFirestore.instance.batch();

    // Update connection arrays for both users
    batch.update(currentUserRef, {'connections': FieldValue.arrayUnion([requestFromId])});
    batch.update(otherUserRef, {'connections': FieldValue.arrayUnion([_currentUser.uid])});

    // Remove from request arrays for both users
    batch.update(currentUserRef, {'receivedRequests': FieldValue.arrayRemove([requestFromId])});
    batch.update(otherUserRef, {'sentRequests': FieldValue.arrayRemove([_currentUser.uid])});
    
    await batch.commit();

    // --- NEW: LOGIC TO CREATE "CONNECTION ACCEPTED" NOTIFICATION ---
    final currentUserDoc = await currentUserRef.get();
    final currentUserData = currentUserDoc.data() ?? {};
    
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': requestFromId, // The ID of the user to be notified
      'title': 'Connection Accepted',
      'body': '${currentUserData['displayName'] ?? 'Someone'} accepted your connection request.',
      'type': 'connection_accepted', 
      'relatedDocId': _currentUser.uid, // Link back to the current user's profile
      'triggeringUserId': _currentUser.uid,
      'triggeringUserName': currentUserData['displayName'] ?? 'Someone',
      'triggeringUserAvatarUrl': currentUserData['profilePhotoUrl'] ?? '',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _declineRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance.collection('users').doc(requestFromId);

    final batch = FirebaseFirestore.instance.batch();
    batch.update(currentUserRef, {'receivedRequests': FieldValue.arrayRemove([requestFromId])});
    batch.update(otherUserRef, {'sentRequests': FieldValue.arrayRemove([_currentUser.uid])});

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Connection Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> receivedRequests = userData['receivedRequests'] ?? [];

          if (receivedRequests.isEmpty) {
            return Center(
              child: Text('No new requests.', style: GoogleFonts.poppins(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final userId = receivedRequests[index];
              
              // Use FutureBuilder to fetch details of the user who sent the request
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  if (!userSnapshot.data!.exists) {
                    // This can happen if the user who sent the request deletes their account.
                    // We can choose to show nothing or a placeholder.
                    return const SizedBox.shrink(); 
                  }
                  final requestUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userImage = requestUserData['profilePhotoUrl'] ?? '';

                  // Simple fade-in animation for each item
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId))),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                              child: userImage.isEmpty ? const Icon(Icons.person) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(requestUserData['displayName'] ?? 'A User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                Text('@${requestUserData['username'] ?? ''}', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _acceptRequest(userId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9983F3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _declineRequest(userId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Decline'),
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
          );
        },
      ),
    );
  }
}