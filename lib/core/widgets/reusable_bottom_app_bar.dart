import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_project/core/utils/fade_page_route.dart';
import 'package:my_project/features/campus/presentation/classify_screen.dart';
import 'package:my_project/features/home/presentation/home_screen.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';
// --- The import for 'inbox_screen.dart' is now removed ---

// --- 'inbox' is removed from the enum ---
enum ActiveScreen { home, classify, profile, notifications }

class ReusableBottomAppBar extends StatelessWidget {
  final ActiveScreen activeScreen;

  const ReusableBottomAppBar({super.key, required this.activeScreen});

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.yellow;
    final Color inactiveColor = Colors.white70;
    final Color bgColor = Colors.grey.shade900;
    final currentUser = FirebaseAuth.instance.currentUser;

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
              icon: Icon(
                activeScreen == ActiveScreen.home ? Icons.home_filled : Icons.home_outlined,
                color: activeScreen == ActiveScreen.home ? activeColor : inactiveColor,
              ),
              onPressed: () {
                if (activeScreen != ActiveScreen.home) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(child: const HomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            // --- Classify Button ---
            IconButton(
              tooltip: 'Classify',
              icon: Icon(
                activeScreen == ActiveScreen.classify ? Icons.apps : Icons.apps_outlined,
                color: activeScreen == ActiveScreen.classify ? activeColor : inactiveColor,
              ),
              onPressed: () {
                if (activeScreen != ActiveScreen.classify) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(child: const ClassifyScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 40), // The space for the FloatingActionButton

            // --- The Inbox button has been removed from here ---

            // --- Profile Button ---
            IconButton(
              tooltip: 'Profile',
              icon: Icon(
                activeScreen == ActiveScreen.profile ? Icons.person : Icons.person_outline,
                color: activeScreen == ActiveScreen.profile ? activeColor : inactiveColor,
              ),
              onPressed: () {
                if (currentUser != null && activeScreen != ActiveScreen.profile) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(child: ProfileScreen(userId: currentUser.uid)),
                    (route) => false,
                  );
                }
              },
            ),

            // --- Notifications Button (restored) ---
            IconButton(
              tooltip: 'Notifications',
              icon: Icon(
                activeScreen == ActiveScreen.notifications ? Icons.notifications : Icons.notifications_none,
                color: activeScreen == ActiveScreen.notifications ? activeColor : inactiveColor,
              ),
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