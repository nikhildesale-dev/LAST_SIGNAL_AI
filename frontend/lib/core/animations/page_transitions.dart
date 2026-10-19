import 'package:flutter/material.dart';

/// Smooth fade and slide page transition route for LAST SIGNAL AI
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.04, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final slideTween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
        );
}

/// Helper for staggered animated card entrances
class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 60),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * delay.inMilliseconds)),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - value)),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
