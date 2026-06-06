// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: lib/features/dashboard/presentation/main_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ⚠️ IMPORTANT: Ensure you have added curved_navigation_bar to your pubspec.yaml
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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
  // Visual index for the CurvedNavigationBar (0 to 4)
  int _navBarIndex = 0;
  DateTime? _lastPressedAt;

  late final List<Widget> _pages;
  late final PageController _pageController;

  // GlobalKey to securely sync the page swipe with the curved nav bar
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Determine the initial logical page index (0 to 3)
    int initialPage = _getPageFromNavIndex(_navBarIndex);
    _pageController = PageController(initialPage: initialPage);

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

  // Helper method: Maps 4-page swipe index to the 5-item nav bar index
  int _getNavIndexFromPage(int pageIndex) {
    if (pageIndex == 0) return 0; // Home
    if (pageIndex == 1) return 1; // Explore
    if (pageIndex == 2) return 3; // Tools (skips the middle button at index 2)
    if (pageIndex == 3) return 4; // Profile
    return 0;
  }

  // Helper method: Maps 5-item nav bar index back to the 4-page index
  int _getPageFromNavIndex(int navIndex) {
    if (navIndex == 0) return 0;
    if (navIndex == 1) return 1;
    if (navIndex == 3) return 2;
    if (navIndex == 4) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- THEME COLORS ---
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final bottomBarColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

    // --- BRANDING COLORS ---
    const Color violetActiveColor = Color(0xFF9983F3); // App's brand Violet
    final Color inactiveIconColor =
        isDark ? Colors.white54 : Colors.grey.shade400;

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
        // Crucial for the transparent curve illusion at the bottom
        extendBody: true,
        body: PageView(
          controller: _pageController,
          // Ultra-Smooth Bouncing Swipes RESTORED!
          physics: const BouncingScrollPhysics(),
          onPageChanged: (pageIndex) {
            int mappedNavIndex = _getNavIndexFromPage(pageIndex);

            // Sync the Navigation bar bubble if swiped manually
            if (_navBarIndex != mappedNavIndex) {
              setState(() {
                _navBarIndex = mappedNavIndex;
              });
              _bottomNavigationKey.currentState?.setPage(mappedNavIndex);
            }
          },
          children: _pages,
        ),

        // --- PREMIUM LIQUID ANIMATION NAVBAR ---
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _navBarIndex,
          height: 65.0,
          // Transparent background makes the area around the liquid bubble blend perfectly into the page
          backgroundColor: Colors.transparent,
          color: bottomBarColor,
          // RESTORED: This creates the solid purple bubble behind the active icon
          buttonBackgroundColor: violetActiveColor,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 350),
          letIndexChange: (index) {
            // Block the liquid bubble from selecting the center button
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
              return false; // Prevent animation onto the post button
            }
            return true; // Allow animation for normal tabs
          },
          onTap: (index) {
            // Check if it's a normal page tap (not the center button)
            if (index != 2) {
              int pageIndex = _getPageFromNavIndex(index);

              // Smoothly animate the page transition instead of jumping
              if (_pageController.page?.round() != pageIndex) {
                _pageController.animateToPage(
                  pageIndex,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
              }

              setState(() {
                _navBarIndex = index;
              });
            }
          },
          items: [
            // Tab 0: Home
            Icon(
              _navBarIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
              size: 30,
              color: _navBarIndex == 0 ? Colors.white : inactiveIconColor,
            ),
            // Tab 1: Explore
            Icon(
              _navBarIndex == 1 ? Icons.search_rounded : Icons.search_outlined,
              size: 30,
              color: _navBarIndex == 1 ? Colors.white : inactiveIconColor,
            ),

            // --- NEW: HIGHLY PROFESSIONAL COMPOSE BUTTON ---
            // Uses a sleek rounded rectangle (squircle) with an 'edit/compose' icon
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  14,
                ), // Premium Squircle shape
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF9983F3),
                    Color(0xFFFF4B72),
                  ], // Brand Purple to Pink
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4B72).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_square, // Professional "Compose/Create" icon
                size: 24,
                color: Colors.white,
              ),
            ),

            // Tab 3: Tools/Classify
            Icon(
              _navBarIndex == 3
                  ? Icons.grid_view_rounded
                  : Icons.grid_view_outlined,
              size: 30,
              color: _navBarIndex == 3 ? Colors.white : inactiveIconColor,
            ),
            // Tab 4: Profile & Notifications
            NotificationBadge(
              child: Icon(
                _navBarIndex == 4
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                size: 30,
                color: _navBarIndex == 4 ? Colors.white : inactiveIconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widget to maintain state across tabs ---
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
