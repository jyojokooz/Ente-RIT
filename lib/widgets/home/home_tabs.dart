import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTabs extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChanged;
  final bool isDark;
  final Color cardColor;

  const HomeTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.isDark,
    required this.cardColor,
  });

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? const LinearGradient(
                      colors: [Color(0xFFB165FF), Color(0xFFFF4B72)],
                    )
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color:
                  isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [_buildTab("Recent", 0), _buildTab("Trending", 1)],
        ),
      ),
    );
  }
}
