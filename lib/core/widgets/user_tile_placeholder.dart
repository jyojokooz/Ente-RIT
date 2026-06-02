import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // <-- THIS IS THE FIX

class UserTilePlaceholder extends StatelessWidget {
  const UserTilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(
          height: 16,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 12,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
