import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- FIX: Import the correct, working chat screens ---
import 'chat_screen.dart';
import 'chat_list_screen.dart';

class LostFoundDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot itemDoc;
  const LostFoundDetailScreen({super.key, required this.itemDoc});

  // --- FIX: COMPLETELY REWRITTEN CHAT NAVIGATION LOGIC ---
  Future<void> _startOrNavigateToChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Show a message if the user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to contact the poster.'),
        ),
      );
      return;
    }

    final data = itemDoc.data() as Map<String, dynamic>;
    final posterId = data['userId'];
    final posterName = data['userName'] ?? 'User';

    // Fetch the poster's custom profile photo URL from their user document
    String posterPhotoUrl = '';
    try {
      final posterDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(posterId)
              .get();
      if (posterDoc.exists) {
        posterPhotoUrl = posterDoc.data()?['profilePhotoUrl'] ?? '';
      }
    } catch (e) {
      // Could not fetch photo, will use a fallback in ChatScreen
    }

    // Navigate to the main ChatScreen with all the required data
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                receiverId: posterId,
                receiverName: posterName,
                receiverImageUrl: posterPhotoUrl,
              ),
        ),
      );
    }
  }

  Future<void> _markAsResolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(itemDoc.id)
          .update({'isResolved': true});

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as resolved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = itemDoc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyPost = currentUser != null && currentUser.uid == data['userId'];
    final imageUrl = data['imageUrl'] as String?;
    final timestamp = data['createdAt'] as Timestamp?;
    final formattedDate =
        timestamp != null
            ? DateFormat.yMMMMd().add_jm().format(timestamp.toDate())
            : 'Date not available';

    final contentTextStyle = GoogleFonts.poppins(
      fontSize: 15,
      color: Colors.white70,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.grey.shade900,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                data['title'] ?? 'Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background:
                  (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 50,
                          ); // Fallback icon
                        },
                      )
                      : Container(color: Colors.grey.shade800),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusChip(data['status'] ?? 'N/A'),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    Icons.description_outlined,
                    'Description',
                    Text(
                      data['description'] ?? 'No description provided.',
                      style: contentTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    Icons.location_on_outlined,
                    'Last Seen At',
                    Text(data['location'] ?? 'N/A', style: contentTextStyle),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    Icons.person_outline,
                    'Posted By',
                    Text(
                      data['userName'] ?? 'Anonymous',
                      style: contentTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    Icons.calendar_today_outlined,
                    'Date Posted',
                    Text(formattedDate, style: contentTextStyle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(context, isMyPost),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColor =
        status == 'lost' ? Colors.orange.shade800 : Colors.blue.shade800;
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildDetailSection(
    IconData icon,
    String title,
    Widget contentWidget,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.yellow, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: contentWidget,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMyPost) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      child:
          isMyPost
              ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      // --- FIX: This button now goes to the main chat list ---
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const ChatListScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('View Messages'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.yellow,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _markAsResolved(context),
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    iconSize: 30,
                    tooltip: 'Mark as Resolved',
                  ),
                ],
              )
              : ElevatedButton.icon(
                onPressed: () => _startOrNavigateToChat(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contact Poster'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
    );
  }
}
