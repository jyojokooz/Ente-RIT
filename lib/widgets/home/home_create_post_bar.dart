import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../screens/create_post_screen.dart';

class HomeCreatePostBar extends StatelessWidget {
  final String profilePic;
  final bool isDark;
  final Color cardColor;

  const HomeCreatePostBar({
    super.key,
    required this.profilePic,
    required this.isDark,
    required this.cardColor,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cardColor,
            backgroundImage:
                profilePic.isNotEmpty
                    ? CachedNetworkImageProvider(profilePic)
                    : null,
            child:
                profilePic.isEmpty
                    ? Icon(
                      Icons.person,
                      color: isDark ? Colors.white54 : Colors.grey,
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    _createSmoothRoute(const CreatePostScreen()),
                  ),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Share anything you want.",
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
