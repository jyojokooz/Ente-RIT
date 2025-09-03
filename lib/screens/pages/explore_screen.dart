import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the actual SearchScreen to navigate to it when the user taps the search bar.
import '../search_screen.dart';

/// A "destination" screen that acts as the main "Explore" tab in the app.
///
/// This screen does not perform searches itself. Instead, it provides a prominent
/// search bar that, when tapped, pushes the functional `SearchScreen` onto the stack.
/// The rest of the screen is designed to display curated content like trending posts
/// or suggested users.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  // THIS IS THE FIX:
  // The stray 's' has been removed, leaving only the correct @override annotation.
  @override
  Widget build(BuildContext context) {
    // As a main page, it uses SafeArea, not a Scaffold.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This is a "fake" search bar. It's not a real TextField.
            // It's a styled Container that the user can tap to initiate a search.
            // This is a better UX for a main tab, as it prevents the keyboard
            // from popping up automatically every time the tab is selected.
            GestureDetector(
              onTap: () {
                // Navigate to the real, functional search screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70),
                    SizedBox(width: 12),
                    Text(
                      'Search',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // This is where you would add other content for the explore page.
            Text(
              'Suggested for You',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Placeholder for future content (e.g., a grid of posts or list of users).
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 60,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trending posts and suggested users\nwill appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
