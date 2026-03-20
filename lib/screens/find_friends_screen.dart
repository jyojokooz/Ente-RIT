import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'pages/profile_screen.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  List<Map<String, dynamic>> _suggestedUsers = [];
  final Set<String> _requestedIds =
      {}; // Tracks users we just sent a request to

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final myUid = _currentUser.uid;
      final myDoc =
          await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (!myDoc.exists) return;

      final myData = myDoc.data()!;
      final List<dynamic> myConnections = myData['connections'] ?? [];
      final List<dynamic> mySent = myData['sentRequests'] ?? [];
      final List<dynamic> myReceived = myData['receivedRequests'] ?? [];

      // Users to exclude from suggestions
      final Set<String> excludeIds = {
        myUid,
        ...myConnections.map((e) => e.toString()),
        ...mySent.map((e) => e.toString()),
        ...myReceived.map((e) => e.toString()),
      };

      // Fetch all users
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> suggestions = [];

      for (var doc in usersSnap.docs) {
        if (excludeIds.contains(doc.id)) continue;

        final theirData = doc.data();
        final List<dynamic> theirConnections = theirData['connections'] ?? [];

        // Calculate Mutual Friends
        int mutualCount = 0;
        for (var conn in theirConnections) {
          if (myConnections.contains(conn)) {
            mutualCount++;
          }
        }

        suggestions.add({'doc': doc, 'mutualCount': mutualCount});
      }

      // Sort by mutual friends (Highest first)
      suggestions.sort(
        (a, b) => (b['mutualCount'] as int).compareTo(a['mutualCount'] as int),
      );

      if (mounted) {
        setState(() {
          _suggestedUsers = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  Future<void> _sendRequest(String targetUserId) async {
    // Optimistic UI update
    setState(() {
      _requestedIds.add(targetUserId);
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final meRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid);
      final themRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId);

      batch.update(meRef, {
        'sentRequests': FieldValue.arrayUnion([targetUserId]),
      });
      batch.update(themRef, {
        'receivedRequests': FieldValue.arrayUnion([_currentUser.uid]),
      });

      await batch.commit();
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _requestedIds.remove(targetUserId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find Friends',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
              )
              : _suggestedUsers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 60,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No new suggestions",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You've connected with everyone!",
                      style: GoogleFonts.poppins(
                        color: mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadSuggestions,
                color: const Color(0xFFFF3E8E),
                backgroundColor: cardColor,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _suggestedUsers.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestedUsers[index];
                    final DocumentSnapshot doc = suggestion['doc'];
                    final int mutualCount = suggestion['mutualCount'];
                    final userData = doc.data() as Map<String, dynamic>;

                    final String userId = doc.id;
                    final String displayName =
                        userData['displayName'] ?? 'User';
                    final String username = userData['username'] ?? '';
                    final String photoUrl = userData['profilePhotoUrl'] ?? '';
                    final bool isRequested = _requestedIds.contains(userId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: userId),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              backgroundImage:
                                  photoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(photoUrl)
                                      : null,
                              child:
                                  photoUrl.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        color: mutedTextColor,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@$username',
                                    style: GoogleFonts.poppins(
                                      color: mutedTextColor,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        mutualCount > 0
                                            ? Icons.people_alt_rounded
                                            : Icons.flare_rounded,
                                        size: 12,
                                        color:
                                            mutualCount > 0
                                                ? const Color(0xFF00C6FB)
                                                : const Color(0xFFFF9A44),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mutualCount > 0
                                            ? '$mutualCount mutual friends'
                                            : 'New to campus',
                                        style: GoogleFonts.poppins(
                                          color:
                                              mutualCount > 0
                                                  ? const Color(0xFF00C6FB)
                                                  : const Color(0xFFFF9A44),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient:
                                      isRequested
                                          ? null
                                          : const LinearGradient(
                                            colors: [
                                              Color(0xFFFF3E8E),
                                              Color(0xFFFF9A44),
                                            ],
                                          ),
                                  color:
                                      isRequested
                                          ? (isDark
                                              ? Colors.white10
                                              : Colors.grey.shade200)
                                          : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      isRequested
                                          ? null
                                          : () => _sendRequest(userId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isRequested ? "Sent" : "Mingle",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isRequested
                                              ? mutedTextColor
                                              : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
