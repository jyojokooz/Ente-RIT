// ===============================
// FILE NAME: main_screen.dart
// FILE PATH: C:\Ente-RITEEE\Ente-RIT\lib\screens\main_screen.dart
// ===============================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- FIXED IMPORTS ---
// Using absolute package paths is more robust and solves the errors.
import 'package:my_project/screens/pages/pages.dart';
import 'package:my_project/screens/create_post_screen.dart';
import 'package:my_project/widgets/notification_badge.dart';
// --- END OF FIX ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  late final List<Widget> _pages;
  late final PageController _pageController; // Added PageController for swiping

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Initialize the PageController with the starting index
    _pageController = PageController(initialPage: _currentIndex);

    // Wrapped pages in KeepAlivePage to prevent them from reloading when swiped away
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
    _pageController.dispose(); // Dispose the controller to prevent memory leaks
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

    // Animate to the page when a bottom nav item is tapped
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Called when the user swipes left/right
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brandPurple = isDark ? Colors.yellow : const Color(0xFF9983F3);

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
        backgroundColor: theme.scaffoldBackgroundColor,

        // Replaced IndexedStack with PageView for swipe gestures
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics:
              const BouncingScrollPhysics(), // Gives a nice iOS-style bounce
          children: _pages,
        ),

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
                    decoration: BoxDecoration(
                      color: brandPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
            ),
          ),
        ),

        bottomNavigationBar: BottomAppBar(
          height: 55,
          color: theme.bottomAppBarTheme.color,
          elevation: 0,
          surfaceTintColor: theme.bottomAppBarTheme.color,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabIcon(Icons.home, Icons.home_outlined, 0, 0, theme),
                _buildTabIcon(Icons.search, Icons.search_outlined, 1, 1, theme),
                const SizedBox(width: 48),
                _buildTabIcon(Icons.apps, Icons.apps_outlined, 2, 3, theme),
                _buildTabIcon(
                  Icons.person,
                  Icons.person_outline,
                  3,
                  4,
                  theme,
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
    ThemeData theme, {
    bool isProfile = false,
  }) {
    final bool isSelected = _currentIndex == pageIndex;
    final color =
        isSelected ? theme.colorScheme.onSurface : Colors.grey.shade500;

    Widget icon = Icon(
      isSelected ? activeIcon : inactiveIcon,
      color: color,
      size: 28,
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
// This prevents pages from reloading/losing scroll position when swiping away
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
    super.build(context); // Crucial step for AutomaticKeepAliveClientMixin
    return widget.child;
  }
}
