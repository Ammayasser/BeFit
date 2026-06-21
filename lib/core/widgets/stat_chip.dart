import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../utils/responsive.dart'; // responsive

class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1); // responsive
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = color ?? colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s), // responsive
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * s), // responsive
        border: Border.all(
          color: displayColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16 * s, // responsive
              color: displayColor,
            ),
            SizedBox(width: 8 * s), // responsive
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  color: colorScheme.onSurface,
                  fontSize: Responsive.fontScale(context, 16), // responsive
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: Responsive.fontScale(context, 11), // responsive
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
