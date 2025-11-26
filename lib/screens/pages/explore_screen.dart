// ===============================
// FILE NAME: explore_screen.dart
// FILE PATH: lib/screens/pages/explore_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the actual SearchScreen
import '../search_screen.dart';
// NEW: Import requests screen for the "Find Friends" button
import '../requests_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // --- 1. Search Bar ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'Search for users...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. FIND FRIENDS / SUGGESTIONS SECTION ---
          ListTile(
            onTap: () {
              // You can create a new screen for this
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User suggestions coming soon!")),
              );
            },
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF9983F3),
              child: Icon(Icons.people_alt_outlined, color: Colors.white),
            ),
            title: Text(
              "Find Friends",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "Connect with people you may know",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequestsScreen()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade300,
              child: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.white,
              ),
            ),
            title: Text(
              "Connection Requests",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "View pending requests",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // --- 3. TRENDING/DISCOVERY SECTION ---
          Text(
            'Trending Posts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder for a grid of trending posts
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 50,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trending posts will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
