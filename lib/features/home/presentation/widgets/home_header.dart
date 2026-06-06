import 'package:flutter/material.dart';
import 'package:my_project/features/notifications/presentation/notifications_screen.dart';
import 'package:my_project/features/chat/presentation/chat_list_screen.dart';
import 'package:my_project/features/notifications/presentation/widgets/notification_badge.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final bool isDark;
  final Color textColor;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.isDark,
    required this.textColor,
  });

  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildTopBarButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF252528) : Colors.white,
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            isDark
                ? 'assets/enterit_logo.png'
                : 'assets/enterit_logo_light.png',
            height: 38,
            fit: BoxFit.contain,
            // FIX: Removed the Text fallback so it doesn't flash laggy text
            errorBuilder:
                (context, error, stackTrace) =>
                    const SizedBox(width: 120, height: 38),
          ),
          Row(
            children: [
              NotificationBadge(
                child: _buildTopBarButton(
                  context,
                  icon: Icons.notifications_none_rounded,
                  onTap:
                      () => Navigator.push(
                        context,
                        _createSmoothRoute(const NotificationsScreen()),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTopBarButton(
                context,
                icon: Icons.maps_ugc_rounded,
                onTap:
                    () => Navigator.push(
                      context,
                      _createSmoothRoute(const ChatListScreen()),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
