// ===============================
// FILE NAME: wishlist_button.dart
// FILE PATH: lib/widgets/wishlist_button.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:my_project/features/marketplace/data/marketplace_service.dart';

class WishlistButton extends StatelessWidget {
  final String productId;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final bool withBackground;

  const WishlistButton({
    super.key,
    required this.productId,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.size = 24,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final MarketplaceService service = MarketplaceService();

    return StreamBuilder<List<String>>(
      stream: service.getWishlistStream(),
      builder: (context, snapshot) {
        final wishlist = snapshot.data ?? [];
        final isLiked = wishlist.contains(productId);

        Widget icon = Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? activeColor : inactiveColor,
          size: size,
        );

        if (withBackground) {
          return GestureDetector(
            onTap: () => service.toggleWishlist(productId),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25), // Subtle shadow
                    blurRadius: 5,
                  ),
                ],
              ),
              child: icon,
            ),
          );
        }

        return IconButton(
          onPressed: () => service.toggleWishlist(productId),
          icon: icon,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }
}
