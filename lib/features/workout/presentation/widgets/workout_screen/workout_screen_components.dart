import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit/core/constants/app_colors.dart';

class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HeaderCircleButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;

    return Material(
      color: isDark ? colors.surfaceCard : Colors.white,
      shape: const CircleBorder(),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isDark ? Border.all(color: colors.border) : null,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
      ),
    );
  }
}

class HeaderPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HeaderPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubsectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final TextStyle Function({
    double size,
    FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
  }) textStyle;
  final VoidCallback? onMore;

  const SubsectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    required this.textStyle,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title ($trailing)',
          style: textStyle(size: 15, fontWeight: FontWeight.w800),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceCard : const Color(0xFFF8FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
          ),
          child: InkWell(
            onTap: onMore,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Icon(
                Icons.more_horiz_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TextActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const TextActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
