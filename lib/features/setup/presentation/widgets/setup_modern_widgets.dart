import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';

class SetupOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const SetupOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  bool get _hasSubtitle => subtitle.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: 14 * s),
      decoration: BoxDecoration(
        color: isSelected
            ? Color.lerp(theme.setupCard, theme.setupPrimary, 0.08)
            : theme.setupCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? theme.setupPrimary
              : theme.border.withValues(alpha: 0.55),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.025),
            blurRadius: isSelected ? 20 : 10,
            offset: const Offset(0, 6),
          ),
          if (isSelected)
            BoxShadow(
              color: theme.setupPrimary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 18 * s),
            child: Row(
              children: [
                Container(
                  width: 54 * s,
                  height: 54 * s,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              theme.setupPrimary.withValues(alpha: 0.2),
                              theme.setupPrimary.withValues(alpha: 0.1),
                            ]
                          : [
                              theme.surfaceElevated,
                              theme.surfaceElevated.withValues(alpha: 0.78),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 24 * s,
                    color: isSelected
                        ? theme.setupPrimary
                        : theme.setupTextSecondary,
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.montserrat(
                                fontSize: Responsive.fontScale(context, 18),
                                fontWeight: FontWeight.w800,
                                color: theme.setupTextPrimary,
                              ),
                            ),
                          ),
                          if (badge != null && badge!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.setupPrimary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.setupPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_hasSubtitle) ...[
                        SizedBox(height: 6 * s),
                        Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: Responsive.fontScale(context, 13),
                            fontWeight: FontWeight.w600,
                            color: theme.setupTextSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12 * s),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 28 * s,
                  height: 28 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.setupPrimary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.setupPrimary
                          : theme.border.withValues(alpha: 0.7),
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16 * s,
                          color: theme.setupOnPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SetupMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String caption;

  const SetupMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });

  bool get _hasCaption => caption.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 24 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.setupCard, theme.setupPrimary.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.setupPrimary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.setupPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: Responsive.fontScale(context, 11),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: theme.setupPrimary,
              ),
            ),
          ),
          SizedBox(height: 14 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: Responsive.fontScale(context, 58),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.4,
                    height: 0.95,
                    color: theme.setupTextPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Padding(
                padding: EdgeInsets.only(bottom: 8 * s),
                child: Text(
                  unit,
                  style: GoogleFonts.montserrat(
                    fontSize: Responsive.fontScale(context, 22),
                    fontWeight: FontWeight.w800,
                    color: theme.setupPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (_hasCaption) ...[
            SizedBox(height: 10 * s),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: Responsive.fontScale(context, 13),
                fontWeight: FontWeight.w600,
                color: theme.setupTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SetupSegmentedToggle extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SetupSegmentedToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected ? theme.setupPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.setupPrimary.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? theme.setupOnPrimary
                        : theme.setupTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SetupRulerPanel extends StatelessWidget {
  final Widget child;

  const SetupRulerPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 18 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.setupCard, theme.setupPrimary.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.setupPrimary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
