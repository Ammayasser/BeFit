import 'dart:ui';
import 'package:befit/core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'exercise_gif_image.dart';

class WorkoutCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String duration;
  final String exercises;
  final String difficulty;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const WorkoutCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.duration,
    required this.exercises,
    required this.difficulty,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  Color _getDifficultyColor(BuildContext context, String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4ADE80);
      case 'advanced':
      case 'expert':
        return const Color(0xFFFF4747);
      default:
        return const Color(0xFFC0FF00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(context, difficulty);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 15 * s,
              offset: Offset(0, 8 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28 * s),
          child: Stack(
            children: [
              // Image
              AspectRatio(
                aspectRatio: 0.85,
                child: ExerciseGifImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Difficulty Badge
              Positioned(
                top: 12 * s,
                left: 12 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8 * s),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8 * s),
                        border: Border.all(
                          color: difficultyColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 9 * fs,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bookmark
              Positioned(
                top: 4 * s,
                right: 4 * s,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Iconsax.archive_1 : Iconsax.archive,
                    color: isSaved ? const Color(0xFFC0FF00) : Colors.white70,
                    size: 20 * s,
                  ),
                  onPressed: onSave,
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.0 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16 * fs,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12 * s),
                      Row(
                        children: [
                          _StatItem(icon: Iconsax.clock, label: duration, s: s, fs: fs),
                          SizedBox(width: 12 * s),
                          _StatItem(icon: Iconsax.weight, label: exercises, s: s, fs: fs),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double s;
  final double fs;

  const _StatItem({required this.icon, required this.label, required this.s, required this.fs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12 * s, color: Colors.white60),
        SizedBox(width: 4 * s),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white70,
            fontSize: 10 * fs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
