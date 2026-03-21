// ===============================
// FILE PATH: lib/screens/create_post/user_tagging_sheet.dart
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserTaggingSheet extends StatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onSaveTags;

  const UserTaggingSheet({
    super.key,
    required this.initialTags,
    required this.onSaveTags,
  });

  @override
  State<UserTaggingSheet> createState() => _UserTaggingSheetState();
}

class _UserTaggingSheetState extends State<UserTaggingSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late Set<String> _selectedUsernames;
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUsernames = Set.from(widget.initialTags);
    // Load an initial list of users immediately
    _performSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSelection(String username) {
    setState(() {
      if (_selectedUsernames.contains(username)) {
        _selectedUsernames.remove(username);
      } else {
        _selectedUsernames.add(username);
      }
    });
  }

  // Debounced search ensures it doesn't query Firebase on every single keystroke
  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(val);
    });
  }

  Future<void> _performSearch(String query) async {
    final formattedQuery = query.replaceAll('@', '').toLowerCase().trim();

    if (mounted) setState(() => _isLoading = true);

    try {
      // If search is empty, just load 20 random/recent users to pick from
      if (formattedQuery.isEmpty) {
        final snap =
            await FirebaseFirestore.instance
                .collection('users')
                .limit(20)
                .get();
        if (mounted) {
          setState(() {
            _searchResults = snap.docs;
            _isLoading = false;
          });
        }
        return;
      }

      // Search by Display Name
      final nameQuery =
          FirebaseFirestore.instance
              .collection('users')
              .where(
                'searchableDisplayName',
                isGreaterThanOrEqualTo: formattedQuery,
              )
              .where(
                'searchableDisplayName',
                isLessThanOrEqualTo: '$formattedQuery\uf8ff',
              )
              .get();

      // Search by Username
      final usernameQuery =
          FirebaseFirestore.instance
              .collection('users')
              .where(
                'searchableUsername',
                isGreaterThanOrEqualTo: formattedQuery,
              )
              .where(
                'searchableUsername',
                isLessThanOrEqualTo: '$formattedQuery\uf8ff',
              )
              .get();

      // Run both queries simultaneously and merge results
      final results = await Future.wait([nameQuery, usernameQuery]);
      final Map<String, DocumentSnapshot> combinedResults = {};

      for (var doc in results[0].docs) combinedResults[doc.id] = doc;
      for (var doc in results[1].docs) combinedResults[doc.id] = doc;

      if (mounted) {
        setState(() {
          _searchResults = combinedResults.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed height percentage prevents layout jumping when keyboard appears
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ),
                Text(
                  "Tag People",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSaveTags(_selectedUsernames.toList());
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Done",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected Tags Display (Horizontal Scroll)
          if (_selectedUsernames.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsernames.length,
                itemBuilder: (context, index) {
                  final username = _selectedUsernames.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text("@$username"),
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white70,
                      ),
                      onDeleted: () => _toggleSelection(username),
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                  );
                },
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search name or username...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search Results List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                    : _searchResults.isEmpty
                    ? Center(
                      child: Text(
                        "No users found",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    )
                    : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final userData =
                            _searchResults[index].data()
                                as Map<String, dynamic>;
                        final username = userData['username'] ?? '';
                        final displayName = userData['displayName'] ?? 'User';
                        final profilePic = userData['profilePhotoUrl'] ?? '';
                        final isSelected = _selectedUsernames.contains(
                          username,
                        );

                        return ListTile(
                          onTap: () => _toggleSelection(username),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage:
                                profilePic.isNotEmpty
                                    ? CachedNetworkImageProvider(profilePic)
                                    : null,
                            child:
                                profilePic.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                    )
                                    : null,
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "@$username",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blueAccent
                                        : Colors.white54,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
