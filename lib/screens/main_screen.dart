import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Screen Imports ---
import 'pages/pages.dart';
import 'create_post_screen.dart';

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
    _pages = [
      const HomeScreen(),
      const ClassifyScreen(),
      if (currentUser != null)
        ProfileScreen(userId: currentUser.uid)
      else
        const Center(child: Text("Error: User not found.")),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

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
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
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
            // --- Home Button ---
            IconButton(
              tooltip: 'Home',
              // FIX: Removed 'const' because 'activeColor' and 'inactiveColor' are runtime variables.
              icon: Icon(
                _currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
                color: _currentIndex == 0 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(0),
            ),
            // --- Classify Button ---
            IconButton(
              tooltip: 'Classify',
              // FIX: Removed 'const'
              icon: Icon(
                _currentIndex == 1 ? Icons.apps : Icons.apps_outlined,
                color: _currentIndex == 1 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(1),
            ),
            const SizedBox(width: 40), // The space for the FAB
            // --- Profile Button ---
            IconButton(
              tooltip: 'Profile',
              // FIX: Removed 'const'
              icon: Icon(
                _currentIndex == 2 ? Icons.person : Icons.person_outline,
                color: _currentIndex == 2 ? activeColor : inactiveColor,
              ),
              onPressed: () => _onTabTapped(2),
            ),
            // --- Notifications Button ---
            IconButton(
              tooltip: 'Notifications',
              // FIX: Removed 'const' from the Icon widget. This was the specific error you reported.
              icon: Icon(Icons.notifications_none, color: inactiveColor),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications screen coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
