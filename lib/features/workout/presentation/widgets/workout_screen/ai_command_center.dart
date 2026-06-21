// lib/features/workout/presentation/widgets/workout_screen/ai_command_center.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/constants/app_colors.dart';
import 'workout_hub_shared.dart';

class AICommandCenter extends StatelessWidget {
  final VoidCallback onVisionTap;
  final VoidCallback onGeneratorTap;

  const AICommandCenter({
    super.key,
    required this.onVisionTap,
    required this.onGeneratorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    
    // Use a more readable color for light mode
    final brandColor = isDark ? WorkoutHubTokens.lime : AppColors.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22 * s),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
        border: Border.all(
          color: isDark ? colors.border : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: WorkoutHubTokens.lift(
          color: isDark ? Colors.black : Colors.black12,
          s: s,
          cBlur: 10,
          fBlur: 30,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
        child: Stack(
          children: [
            // Decorative Grid Background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  s: s,
                  isDark: isDark,
                  opacity: isDark ? 0.03 : 0.05,
                ),
              ),
            ),
            
            // Background Decorative Letter "A"
            Positioned(
              right: -20 * s,
              top: 20 * s,
              child: Text(
                'AI',
                style: GoogleFonts.montserrat(
                  fontSize: 180 * s,
                  fontWeight: FontWeight.w900,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                  height: 1,
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * s,
                          vertical: 5 * s,
                        ),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8 * s),
                          border: Border.all(
                            color: brandColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.cpu_charge,
                              color: brandColor,
                              size: 12 * s,
                            ),
                            SizedBox(width: 6 * s),
                            Text(
                              'NEURAL ENGINE v2.0',
                              style: GoogleFonts.montserrat(
                                fontSize: 9 * fs,
                                fontWeight: FontWeight.w900,
                                color: brandColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _LivePulse(color: brandColor),
                    ],
                  ),
                  SizedBox(height: 20 * s),
                  Text(
                    'AI Command Center',
                    style: GoogleFonts.montserrat(
                      fontSize: 26 * fs,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    'Advanced intelligence for your fitness core.',
                    style: GoogleFonts.inter(
                      fontSize: 13 * fs,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                  SizedBox(height: 28 * s),

                  // AI Modules
                  _TechModuleTile(
                    title: 'VISION AI',
                    subtitle: 'Real-time form tracking & pose detection',
                    icon: Iconsax.camera,
                    accentColor: brandColor,
                    onTap: onVisionTap,
                    s: s,
                    fs: fs,
                  ),
                  SizedBox(height: 12 * s),
                  _TechModuleTile(
                    title: 'REGENERATE PLAN',
                    subtitle: 'Update your smart schedule with AI',
                    icon: Iconsax.magicpen,
                    accentColor: brandColor,
                    onTap: onGeneratorTap,
                    s: s,
                    fs: fs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05, end: 0);
  }
}

class _TechModuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final double s;
  final double fs;

  const _TechModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03);
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(WorkoutHubTokens.rMD * s),
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rMD * s),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WorkoutHubTokens.rMD * s),
            border: Border.all(color: cardBorderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12 * s),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24 * s),
              ),
              SizedBox(width: 18 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16 * fs,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11 * fs,
                        fontWeight: FontWeight.w600,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 18 * s,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double s;
  final bool isDark;
  final double opacity;
  
  _GridPainter({
    required this.s, 
    required this.isDark,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: opacity)
      ..strokeWidth = 0.5;

    final step = 25.0 * s;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 1.0 - _ctrl.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * (1.0 - _ctrl.value)),
                blurRadius: 8 * _ctrl.value,
                spreadRadius: 4 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
