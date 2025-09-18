import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Screen Imports ---
import 'pages/pages.dart';
import 'create_post_screen.dart';

// --- Widget Imports ---
import '../widgets/notification_badge.dart'; // Import the badge widget

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    // This list defines the pages that correspond to the bottom navigation bar items.
    _pages = [
      const HomeScreen(), // Index 0
      const ExploreScreen(), // Index 1
      const ClassifyScreen(), // Index 2
      if (currentUser != null) // Index 3
        ProfileScreen(userId: currentUser.uid)
      else
        const Center(child: Text("Error: User not found.")),
    ];
  }

  // Updates the state to show the selected page when a tab is tapped.
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

    // PopScope handles the device's back button to prevent accidental exits.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        final now = DateTime.now();
        final isFirstPress =
            _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (isFirstPress) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop(); // Exits the app if back is pressed again quickly.
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // IndexedStack efficiently shows only the currently active page.
        // The notification listener is now managed by the AuthGate.
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButton: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              ),
          backgroundColor: primaryAccentColor,
          elevation: 4.0,
          child: const Icon(Icons.add, color: buttonTextColor, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomAppBar(),
      ),
    );
  }

  /// Builds the custom BottomAppBar with a centered notch and notification badge.
  Widget _buildBottomAppBar() {
    const Color activeColor = Colors.yellow;
    final Color inactiveColor = Colors.white70;
    final Color bgColor = Colors.grey.shade900;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      color: bgColor,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // --- Home Button (Index 0) ---
            IconButton(
              tooltip: 'Home',
              icon: Icon(
                _currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
                color: _currentIndex == 0 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(0),
            ),
            // --- Explore Button (Index 1) ---
            IconButton(
              tooltip: 'Explore',
              icon: Icon(
                _currentIndex == 1 ? Icons.search : Icons.search_outlined,
                color: _currentIndex == 1 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(1),
            ),

            // The empty space for the Floating Action Button.
            const SizedBox(width: 40),

            // --- Classify Button (Index 2) ---
            IconButton(
              tooltip: 'Classify',
              icon: Icon(
                _currentIndex == 2 ? Icons.apps : Icons.apps_outlined,
                color: _currentIndex == 2 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(2),
            ),
            // --- Profile Button (Index 3) with Notification Badge ---
            NotificationBadge(
              child: IconButton(
                tooltip: 'Profile',
                icon: Icon(
                  _currentIndex == 3 ? Icons.person : Icons.person_outline,
                  color: _currentIndex == 3 ? activeColor : inactiveColor,
                ),
                onPressed: () => _onTabTapped(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
