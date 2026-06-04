// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: lib/screens/main_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:my_project/features/home/presentation/home_screen.dart';
import 'package:my_project/features/explore/presentation/explore_screen.dart';
import 'package:my_project/features/campus/presentation/classify_screen.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';
import 'package:my_project/features/posts/presentation/create_post_screen.dart';
import 'package:my_project/features/notifications/presentation/widgets/notification_badge.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  late final List<Widget> _pages;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    _pageController = PageController(initialPage: _currentIndex);

    _pages = [
      const KeepAlivePage(child: HomeScreen()),
      const KeepAlivePage(child: ExploreScreen()),
      const KeepAlivePage(child: ClassifyScreen()),
      if (currentUser != null)
        KeepAlivePage(child: ProfileScreen(userId: currentUser.uid))
      else
        const KeepAlivePage(
          child: Center(child: Text("Error: User not found.")),
        ),
    ];

    _setupPushNotifications();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setupPushNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Error FCM: $e");
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

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- THEME COLORS ---
    // Background matches the main feed and profile
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    // Bottom Bar matches the elevated card color of the profile
    final bottomBarColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: const Duration(seconds: 2),
              backgroundColor: theme.colorScheme.onSurface,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: GestureDetector(
          onTap: () => _onTabTapped(2),
          child: Container(
            width: 52, // Decreased to a smaller, sleeker size
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder:
                    (c, e, s) => Container(
                      color: const Color(0xFFFF3E8E),
                      // No plus symbol, just a camera fallback if the image fails to load
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
              ),
            ),
          ),
        ),

        bottomNavigationBar: BottomAppBar(
          height: 65,
          color: bottomBarColor, // Applied custom color
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.3),
          surfaceTintColor:
              bottomBarColor, // Ensures Material 3 uses the exact color
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabIcon(
                  Icons.home_rounded,
                  Icons.home_outlined,
                  0,
                  0,
                  isDark,
                ),
                _buildTabIcon(
                  Icons.search_rounded,
                  Icons.search_rounded,
                  1,
                  1,
                  isDark,
                ),
                const SizedBox(width: 48), // Gap for FAB
                _buildTabIcon(
                  Icons.grid_view_rounded,
                  Icons.grid_view_rounded,
                  2,
                  3,
                  isDark,
                ),
                _buildTabIcon(
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  3,
                  4,
                  isDark,
                  isProfile: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabIcon(
    IconData activeIcon,
    IconData inactiveIcon,
    int pageIndex,
    int visualIndex,
    bool isDark, {
    bool isProfile = false,
  }) {
    final bool isSelected = _currentIndex == pageIndex;

    // Modern Accent Color matches the gradient used elsewhere
    const Color activeColor = Color(0xFFFF3E8E);
    final Color inactiveColor = isDark ? Colors.white54 : Colors.grey.shade400;

    Widget icon = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 16 : 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        isSelected ? activeIcon : inactiveIcon,
        color: isSelected ? activeColor : inactiveColor,
        size: isSelected ? 26 : 24, // Slight pop effect when selected
      ),
    );

    if (isProfile) {
      icon = NotificationBadge(child: icon);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(visualIndex),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(height: double.infinity, child: Center(child: icon)),
      ),
    );
  }
}

// --- Helper Widget to maintain state across swipes ---
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
