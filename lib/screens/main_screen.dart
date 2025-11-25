// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: lib/screens/main_screen.dart
// ===============================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Added back for SystemNavigator

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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- NEO-BRUTALIST COLORS ---
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
          SystemNavigator.pop(); // This now works
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: _pages),

        // --- FLOATING ACTION BUTTON (FAB) ---
        floatingActionButton: Container(
          height: 65,
          width: 65,
          margin: const EdgeInsets.only(top: 30),
          child: FloatingActionButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                ),
            backgroundColor: brandPurple,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: brandBlack, width: 3),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 35),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // --- BOTTOM BAR ---
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: brandBlack, width: 3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, -4),
                blurRadius: 0,
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0,
            color: Colors.white,
            elevation: 0,
            height: 75,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavIcon(Icons.home_filled, Icons.home_outlined, 0),
                _buildNavIcon(Icons.search, Icons.search_outlined, 1),
                const SizedBox(width: 40), // Space for FAB
                _buildNavIcon(Icons.apps, Icons.apps_outlined, 2),
                NotificationBadge(
                  child: _buildNavIcon(Icons.person, Icons.person_outline, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData activeIcon, IconData inactiveIcon, int index) {
    const Color brandBlack = Colors.black;
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration:
            isSelected
                ? BoxDecoration(
                  color: Colors.yellow.shade400,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: brandBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                )
                : const BoxDecoration(),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: brandBlack,
          size: 28,
        ),
      ),
    );
  }
}
