import 'package:flutter/material.dart';
// --- FIX APPLIED HERE: Using correct relative paths ---
import '../helpers/fade_page_route.dart';
import '../screens/classify_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

// An enum to represent the active screen for highlighting the icon
enum ActiveScreen { home, classify, profile, notifications }

class ReusableBottomAppBar extends StatelessWidget {
  final ActiveScreen activeScreen;

  const ReusableBottomAppBar({super.key, required this.activeScreen});

  @override
  Widget build(BuildContext context) {
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
            IconButton(
              tooltip: 'Home',
              icon: Icon(
                Icons.home,
                color:
                    activeScreen == ActiveScreen.home
                        ? activeColor
                        : inactiveColor,
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
            IconButton(
              tooltip: 'Classify',
              icon: Icon(
                Icons.category_outlined,
                color:
                    activeScreen == ActiveScreen.classify
                        ? activeColor
                        : inactiveColor,
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
            IconButton(
              tooltip: 'Profile',
              icon: Icon(
                Icons.person_outline,
                color:
                    activeScreen == ActiveScreen.profile
                        ? activeColor
                        : inactiveColor,
              ),
              onPressed: () {
                if (activeScreen != ActiveScreen.profile) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(child: const ProfileScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Notifications',
              icon: Icon(
                Icons.notifications_none,
                color:
                    activeScreen == ActiveScreen.notifications
                        ? activeColor
                        : inactiveColor,
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
