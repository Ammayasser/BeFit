import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool animate;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget logo = Hero(
      tag: 'app_logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2), // Subtle rounded corners for a modern feel
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: Image.asset(
            'assets/images/app-logo/befit-logo.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    if (animate) {
      logo = logo
          .animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          );
    }

    if (!showText) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 24),
        Text(
          'BEFIT',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w900,
            letterSpacing: 6.0,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
