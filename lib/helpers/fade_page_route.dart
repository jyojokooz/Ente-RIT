import 'package:flutter/material.dart';

// This custom PageRoute creates a fade transition instead of the default slide.
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child})
    : super(
        // Set the transition duration to be fast and smooth
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => child,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => FadeTransition(opacity: animation, child: child),
      );
}
