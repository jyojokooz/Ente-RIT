import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart'; // Import the newly refactored profile screen

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
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);

    // This is the "starts with" query for Firestore
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: query)
            .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
            .get();

    if (mounted) {
      setState(() {
        _searchResults = querySnapshot.docs;
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
            hintText: 'Search for users...',
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
              : _searchResults.isEmpty
              ? Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? 'Search for users by their display name.'
                      : 'No users found.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
              : ListView.builder(
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
                    subtitle: Text(userData['username'] ?? 'No Username'),
                    onTap: () {
                      // Navigate to the ProfileScreen, passing the user's ID
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
