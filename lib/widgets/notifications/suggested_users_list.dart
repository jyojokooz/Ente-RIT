// ===============================
// FILE NAME: suggested_users_list.dart
// FILE PATH: lib/widgets/notifications/suggested_users_list.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../screens/pages/profile_screen.dart';

class SuggestedUsersList extends StatefulWidget {
  final Future<List<DocumentSnapshot>> suggestedUsersFuture;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const SuggestedUsersList({
    super.key,
    required this.suggestedUsersFuture,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  State<SuggestedUsersList> createState() => _SuggestedUsersListState();
}

class _SuggestedUsersListState extends State<SuggestedUsersList> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<DocumentSnapshot> _suggestions = [];
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _filterInitialSuggestions();
  }

  // --- THIS IS THE KEY TO THE FIX ---
  // This lifecycle method is called whenever the parent widget rebuilds
  // and passes down a new `suggestedUsersFuture`.
  @override
  void didUpdateWidget(covariant SuggestedUsersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the future provided by the parent is a new one (i.e., on refresh),
    // we re-run our filtering logic.
    if (widget.suggestedUsersFuture != oldWidget.suggestedUsersFuture) {
      _filterInitialSuggestions();
    }
  }

  Future<void> _filterInitialSuggestions() async {
    // Set loading state to true to show a spinner during refresh
    if (mounted) setState(() => _isLoadingInitial = true);

    try {
      // We now get the future directly from the widget properties
      final allUsers = await widget.suggestedUsersFuture;
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .get();

      if (!mounted || !userDoc.exists) return;

      final myData = userDoc.data()!;
      final myConnections = myData['connections'] ?? [];
      final mySentRequests = myData['sentRequests'] ?? [];
      final myReceivedRequests = myData['receivedRequests'] ?? [];

      final Set<String> excludedIds = {
        _currentUserId,
        ...myConnections.map((e) => e.toString()),
        ...mySentRequests.map((e) => e.toString()),
        ...myReceivedRequests.map((e) => e.toString()),
      };

      if (mounted) {
        setState(() {
          _suggestions =
              allUsers.where((doc) => !excludedIds.contains(doc.id)).toList();
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  void _onMingleSent(String userId) {
    if (mounted) {
      setState(() {
        _suggestions.removeWhere((doc) => doc.id == userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FB)),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final userDoc = _suggestions[index];
          return _SuggestedUserCard(
            key: ValueKey(userDoc.id),
            userDoc: userDoc,
            currentUserId: _currentUserId,
            isDark: widget.isDark,
            cardColor: widget.cardColor,
            textColor: widget.textColor,
            onMingleSent: () => _onMingleSent(userDoc.id),
          );
        },
      ),
    );
  }
}

// --- THE CARD WIDGET REMAINS UNCHANGED ---
class _SuggestedUserCard extends StatefulWidget {
  final DocumentSnapshot userDoc;
  final String currentUserId;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onMingleSent;

  const _SuggestedUserCard({
    super.key,
    required this.userDoc,
    required this.currentUserId,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onMingleSent,
  });

  @override
  State<_SuggestedUserCard> createState() => _SuggestedUserCardState();
}

class _SuggestedUserCardState extends State<_SuggestedUserCard> {
  bool _isRequesting = false;

  Future<void> _sendRequest() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    widget.onMingleSent();

    try {
      final targetUserId = widget.userDoc.id;
      final batch = FirebaseFirestore.instance.batch();

      final meRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId);
      final themRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId);

      batch.update(meRef, {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      });
      batch.update(themRef, {
        'receivedRequests': FieldValue.arrayUnion([widget.currentUserId]),
      });

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userDoc.data() as Map<String, dynamic>;
    final userId = widget.userDoc.id;
    final photoUrl = userData['profilePhotoUrl'] ?? '';
    final name = userData['displayName'] ?? 'User';
    final department = userData['department'] ?? 'Student';

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            ),
          ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            if (!widget.isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor:
                  widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage:
                  photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
              child:
                  photoUrl.isEmpty
                      ? Icon(
                        Icons.person,
                        color: widget.isDark ? Colors.white54 : Colors.black54,
                      )
                      : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: widget.textColor,
              ),
            ),
            Text(
              department,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: widget.isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isRequesting
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            "Mingle",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
