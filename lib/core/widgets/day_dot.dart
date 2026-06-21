import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../utils/responsive.dart'; // responsive

class DayDot extends StatelessWidget {
  final String day;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const DayDot({
    super.key,
    required this.day,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1); // responsive
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36 * s, // responsive
        height: 36 * s, // responsive
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(18 * s), // responsive
          border: isActive
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            day,
            style: GoogleFonts.montserrat(
              color: _getTextColor(colorScheme),
              fontSize: Responsive.fontScale(context, 12), // responsive
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isActive) {
      return colorScheme.primary.withOpacity(0.2);
    }
    if (isCompleted) {
      return colorScheme.primary;
    }
    return Colors.transparent;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isCompleted) {
      return colorScheme.onPrimary;
    }
    if (isActive) {
      return colorScheme.primary;
    }
    return colorScheme.onSurfaceVariant;
  }
}
