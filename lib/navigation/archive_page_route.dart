import 'package:flutter/material.dart';

class ArchivePageRoute<T> extends PageRouteBuilder<T> {
  ArchivePageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return child;
          }

          final reveal = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(reveal),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(reveal),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(reveal),
                child: child,
              ),
            ),
          );
        },
      );
}
