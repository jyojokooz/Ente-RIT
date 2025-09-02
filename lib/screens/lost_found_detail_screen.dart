// lib/screens/lost_found_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'private_chat_screen.dart';
import 'item_chats_list_screen.dart';

class LostFoundDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot itemDoc;
  const LostFoundDetailScreen({super.key, required this.itemDoc});

  // --- LOGIC METHODS (UNCHANGED) ---

  Future<void> _markAsResolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(itemDoc.id)
          .update({'isResolved': true});

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked as resolved!')),
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

  Future<void> _startOrNavigateToChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final data = itemDoc.data() as Map<String, dynamic>;
    final posterId = data['userId'];
    final posterName = data['userName'];
    final itemId = itemDoc.id;
    final itemTitle = data['title'];

    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
    final currentUserName = currentUserDoc.data()?['name'] ?? 'User';

    List<String> userIds = [currentUser.uid, posterId];
    userIds.sort();
    final chatId = '${userIds[0]}_${userIds[1]}_$itemId';

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatSnapshot = await chatDoc.get();

    if (!chatSnapshot.exists) {
      await chatDoc.set({
        'users': [currentUser.uid, posterId],
        'userNames': {currentUser.uid: currentUserName, posterId: posterName},
        'itemId': itemId,
        'itemTitle': itemTitle,
        'lastMessage': 'Chat created about "$itemTitle"',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  PrivateChatScreen(chatId: chatId, otherUserName: posterName),
        ),
      );
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
                      ? Image.network(imageUrl, fit: BoxFit.cover)
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

                  // --- THE FIX IS HERE ---
                  // Now the "Posted By" section ONLY shows the user's name.
                  _buildDetailSection(
                    Icons.person_outline,
                    'Posted By',
                    Text(
                      data['userName'] ?? 'Anonymous',
                      style: contentTextStyle,
                    ),
                  ),

                  // --- END OF FIX ---
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
      bottomNavigationBar: _buildActionButtons(context, isMyPost, data),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColor = status == 'lost' ? Colors.orange : Colors.lightBlue;
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

  Widget _buildActionButtons(
    BuildContext context,
    bool isMyPost,
    Map<String, dynamic> data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      color: Colors.black,
      child:
          isMyPost
              ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (c) => ItemChatsListScreen(
                                    itemId: itemDoc.id,
                                    itemTitle: data['title'] ?? 'Item',
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text('View Inquiries'),
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
