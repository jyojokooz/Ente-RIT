import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  // --- FIX APPLIED HERE ---
  // We only need one list to hold all the combined search results.
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
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);

    // Perform two separate queries
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

    // Await both queries to run in parallel
    final results = await Future.wait([nameQuery, usernameQuery]);

    final nameDocs = results[0].docs;
    final usernameDocs = results[1].docs;

    // Use a Map to combine results and automatically handle duplicates
    final combinedResults = <String, DocumentSnapshot>{};
    for (var doc in nameDocs) {
      combinedResults[doc.id] = doc;
    }
    for (var doc in usernameDocs) {
      combinedResults[doc.id] = doc;
    }

    if (mounted) {
      setState(() {
        // --- FIX APPLIED HERE ---
        // Update the single search results list
        _searchResults = combinedResults.values.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              )
              // --- FIX APPLIED HERE ---
              // Check the single search results list
              : _searchResults.isEmpty
              ? Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? 'Search for other users.'
                      : 'No users found.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
              : ListView.builder(
                // --- FIX APPLIED HERE ---
                // Build the list from the single search results list
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final userDoc = _searchResults[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final userImage = userData['profilePhotoUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          userImage.isNotEmpty ? NetworkImage(userImage) : null,
                      child:
                          userImage.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(userData['displayName'] ?? 'No Name'),
                    subtitle: Text('@${userData['username'] ?? 'No Username'}'),
                    onTap: () {
                      // Unfocus the keyboard when a user is tapped
                      FocusScope.of(context).unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProfileScreen(userId: userDoc.id),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
