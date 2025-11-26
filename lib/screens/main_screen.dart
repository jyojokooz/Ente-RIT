// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: lib/screens/main_screen.dart
// ===============================

// ignore_for_file: sized_box_for_whitespace

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Screen Imports ---
import 'pages/pages.dart';
import 'create_post_screen.dart';
import '../widgets/notification_badge.dart';

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
    // IndexedStack now correctly has 4 pages
    _pages = [
      const HomeScreen(),
      const ExploreScreen(),
      const ClassifyScreen(),
      if (currentUser != null)
        ProfileScreen(userId: currentUser.uid)
      else
        const Center(child: Text("Error: User not found.")),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center button
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
      return;
    }

    int pageIndex = index > 2 ? index - 1 : index;
    setState(() {
      _currentIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandPurple = Color(0xFF9983F3);
    const Color brandBlack = Colors.black;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              backgroundColor: brandBlack,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: _pages),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: GestureDetector(
          onTap: () => _onTabTapped(2),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Image.asset(
              'assets/app_icon.png',
              errorBuilder:
                  (c, e, s) => Container(
                    decoration: const BoxDecoration(
                      color: brandPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
            ),
          ),
        ),

        bottomNavigationBar: BottomAppBar(
          height: 55, // REDUCED HEIGHT
          color: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInstagramIcon(Icons.home, Icons.home_outlined, 0, 0),
                _buildInstagramIcon(Icons.search, Icons.search_outlined, 1, 1),
                const SizedBox(width: 48),
                _buildInstagramIcon(Icons.apps, Icons.apps_outlined, 2, 3),
                _buildInstagramIcon(
                  Icons.person,
                  Icons.person_outline,
                  3,
                  4,
                  isProfile: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramIcon(
    IconData activeIcon,
    IconData inactiveIcon,
    int pageIndex,
    int visualIndex, {
    bool isProfile = false,
  }) {
    final bool isSelected = _currentIndex == pageIndex;

    Widget icon = Icon(
      isSelected ? activeIcon : inactiveIcon,
      color: isSelected ? Colors.black : Colors.grey.shade600,
      size: 28,
    );

    if (isProfile) {
      icon = NotificationBadge(child: icon);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(visualIndex),
        behavior: HitTestBehavior.opaque,
        child: Container(height: double.infinity, child: Center(child: icon)),
      ),
    );
  }
}
