// ===============================
// FILE NAME: search_screen.dart
// FILE PATH: lib/screens/search_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/profile_screen.dart';

import '../widgets/user_tile_placeholder.dart';
import '../widgets/empty_state_message.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final formattedQuery = query.toLowerCase().trim();
    if (formattedQuery.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

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

    final usernameQuery =
        FirebaseFirestore.instance
            .collection('users')
            .where('searchableUsername', isGreaterThanOrEqualTo: formattedQuery)
            .where(
              'searchableUsername',
              isLessThanOrEqualTo: '$formattedQuery\uf8ff',
            )
            .get();

    final results = await Future.wait([nameQuery, usernameQuery]);
    final combinedResults = <String, DocumentSnapshot>{};
    for (var doc in results[0].docs) combinedResults[doc.id] = doc;
    for (var doc in results[1].docs) combinedResults[doc.id] = doc;

    if (mounted) {
      setState(() {
        _searchResults = combinedResults.values.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // UPDATED: Now matches Profile Screen's background color
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: theme.iconTheme,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search by name or username...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _buildBody(isSearching, theme),
    );
  }

  Widget _buildBody(bool isSearching, ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => const UserTilePlaceholder(),
      );
    }
    if (!isSearching) {
      return const EmptyStateMessage(
        icon: Icons.search,
        title: 'Find Your Peers',
        subtitle: 'Search for users by their display name or username.',
      );
    }
    if (_searchResults.isEmpty) {
      return const EmptyStateMessage(
        icon: Icons.person_off_outlined,
        title: 'No Users Found',
        subtitle: 'Try a different search term.',
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userDoc = _searchResults[index];
        final userData = userDoc.data() as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                (userData['profilePhotoUrl'] ?? '').isNotEmpty
                    ? NetworkImage(userData['profilePhotoUrl'])
                    : null,
            child:
                (userData['profilePhotoUrl'] ?? '').isEmpty
                    ? const Icon(Icons.person)
                    : null,
          ),
          title: Text(
            userData['displayName'] ?? 'No Name',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '@${userData['username'] ?? 'No Username'}',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userDoc.id),
              ),
            );
          },
        );
      },
    );
  }
}
