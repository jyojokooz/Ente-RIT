// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: lib/screens/main_screen.dart
// ===============================

// ignore_for_file: sized_box_for_whitespace, curly_braces_in_flow_control_structures

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen Imports ---
import 'pages/pages.dart'; // Ensure this exports HomeScreen, ExploreScreen, etc.
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

    // SETUP PUSH NOTIFICATIONS
    _setupPushNotifications();
  }

  // --- FCM TOKEN SETUP ---
  Future<void> _setupPushNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    // 1. Request Permission
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Get the Token
    try {
      String? token = await messaging.getToken();

      // 3. Save Token to Firestore
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("FCM Token saved for user ${user.uid}: $token");
      }

      // 4. Handle token refresh
      messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Error getting or saving FCM token: $e");
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
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
          height: 55,
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
                const SizedBox(width: 48), // Space for FAB
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
