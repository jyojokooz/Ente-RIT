import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/profile_screen.dart';

// Import our new helper widgets
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

  // The search logic itself is already efficient and remains unchanged.
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
    final nameDocs = results[0].docs;
    final usernameDocs = results[1].docs;

    final combinedResults = <String, DocumentSnapshot>{};
    for (var doc in nameDocs) {
      combinedResults[doc.id] = doc;
    }
    for (var doc in usernameDocs) {
      combinedResults[doc.id] = doc;
    }

    if (mounted) {
      setState(() {
        _searchResults = combinedResults.values.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current state to show the correct UI
    final bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black, // Consistent background color
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900, // Consistent AppBar color
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search by name or username...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
      ),
      // The body logic is now cleaner and more descriptive
      body: _buildBody(isSearching),
    );
  }

  Widget _buildBody(bool isSearching) {
    // State 1: Loading results
    if (_isLoading) {
      // Show a list of shimmering placeholders for a professional loading experience
      return ListView.builder(
        itemCount: 8, // Show a few placeholders to fill the screen
        itemBuilder: (context, index) => const UserTilePlaceholder(),
      );
    }

    // State 2: No search term entered yet
    if (!isSearching) {
      return const EmptyStateMessage(
        icon: Icons.search,
        title: 'Find Your Peers',
        subtitle: 'Search for users by their display name or username.',
      );
    }

    // State 3: Search term entered, but no results found
    if (_searchResults.isEmpty) {
      return const EmptyStateMessage(
        icon: Icons.person_off_outlined,
        title: 'No Users Found',
        subtitle: 'Try a different search term.',
      );
    }

    // State 4: Search results are available
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userDoc = _searchResults[index];
        final userData = userDoc.data() as Map<String, dynamic>;

        return _UserSearchResultTile(
          userData: userData,
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

// A dedicated, styled widget for displaying a search result.
class _UserSearchResultTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onTap;

  const _UserSearchResultTile({required this.userData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userImage = userData['profilePhotoUrl'] ?? '';
    final displayName = userData['displayName'] ?? 'No Name';
    final username = userData['username'] ?? 'No Username';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
        child: userImage.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        displayName,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '@$username',
        style: GoogleFonts.poppins(color: Colors.white70),
      ),
      onTap: onTap,
    );
  }
}
