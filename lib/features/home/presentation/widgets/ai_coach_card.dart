library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:befit/core/router/navigation_provider.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:provider/provider.dart';

class AiCoachCard extends StatelessWidget {
  const AiCoachCard({super.key});

  static const String _tip =
      'Stay consistent — your best sessions come from showing up, not just '
      'from how you feel before you start. Log your workout today.';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = HomeUi.accent(context);
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      decoration: cardDecoration(context),
      padding: EdgeInsets.all(kCardInnerPadding * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38 * s,
                height: 38 * s,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, HomeUi.accentSecondary(context)],
                  ),
                  borderRadius: BorderRadius.circular(14 * s),
                ),
                child: Icon(
                  PhosphorIconsRegular.sparkle,
                  size: 18 * s,
                  color: Colors.white,
                  semanticLabel: 'AI Coach',
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach',
                      style: GoogleFonts.montserrat(
                        fontSize: 17 * fs,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Daily insight',
                      style: GoogleFonts.montserrat(
                        fontSize: 12 * fs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * s),
          Container(
            padding: EdgeInsets.all(14 * s),
            width: double.infinity,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(color: accent.withValues(alpha: 0.10)),
            ),
            child: Text(
              _tip,
              style: GoogleFonts.montserrat(
                fontSize: 14 * fs,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                height: 1.55,
              ),
            ),
          ),
          SizedBox(height: 14 * s),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<NavigationProvider>().setIndex(3);
              },
              icon: Icon(
                PhosphorIconsRegular.chatCircleDots,
                size: 16 * s,
                color: Colors.white,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Ask AI Coach',
                  style: GoogleFonts.montserrat(
                    fontSize: 14 * fs,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14 * s),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * s),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

