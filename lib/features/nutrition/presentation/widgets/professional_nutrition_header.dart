import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'nutrition_colors.dart';

class ProfessionalNutritionHeader extends StatelessWidget {
  final VoidCallback onAddFood;
  final VoidCallback onRecipes;
  final VoidCallback onWater;
  final VoidCallback onScan;

  const ProfessionalNutritionHeader({
    super.key,
    required this.onAddFood,
    required this.onRecipes,
    required this.onWater,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = size.width / 390;
    final isTablet = size.width > 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 0 : 20 * s,
            vertical: 16 * s,
          ),
          color: Colors.transparent,
          child: Column(
            children: [
              // 1. Top Action Bento Row
              Row(
                children: [
                  Expanded(
                    child: _ModernActionPill(
                      label: 'Find Food',
                      icon: Iconsax.search_normal_1,
                      color: const Color(0xFF4C85F7),
                      onTap: onAddFood,
                      s: s,
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: _ModernActionPill(
                      label: 'Recipes',
                      icon: Iconsax.book,
                      color: const Color(0xFF8B5CF6),
                      onTap: onRecipes,
                      s: s,
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: _ModernActionPill(
                      label: 'Water',
                      emoji: '💧',
                      color: const Color(0xFF0EA5E9),
                      onTap: onWater,
                      s: s,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * s),

              // 2. Featured AI Scanner Card
              _ModernFeaturedScannerCard(onTap: onScan, s: s),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final VoidCallback onTap;
  final double s;

  const _ModernActionPill({
    required this.label,
    this.icon,
    this.emoji,
    required this.color,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58 * s,
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: BorderRadius.circular(22 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
        border: Border.all(color: NColors.divider(context).withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(22 * s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null)
                Text(emoji!, style: GoogleFonts.montserrat(fontSize: 18 * s))
              else if (icon != null)
                Icon(icon!, color: color.withValues(alpha: 0.8), size: 20 * s),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: NColors.textPrimary(context),
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernFeaturedScannerCard extends StatelessWidget {
  final VoidCallback onTap;
  final double s;

  const _ModernFeaturedScannerCard({required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 140 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 30 * s,
            offset: Offset(0, 12 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Stack(
            children: [
              // Abstract Glassy Overlay
              Positioned(
                top: -30 * s,
                right: -30 * s,
                child: Container(
                  width: 150 * s,
                  height: 150 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(24 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4 * s),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6 * s),
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  color: const Color(0xFFFACC15),
                                  size: 14 * s,
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Text(
                                'AI POWERED',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10 * s,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12 * s),
                          Text(
                            'Scan Your Meal',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 24 * s,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8 * s),
                          Text(
                            'Track nutrition instantly\nwith advanced vision.',
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    // Futuristic Lens Button
                    Container(
                      width: 76 * s,
                      height: 76 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5 * s),
                      ),
                      child: Center(
                        child: Container(
                          width: 54 * s,
                          height: 54 * s,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Iconsax.camera,
                            color: const Color(0xFF0F172A),
                            size: 26 * s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
