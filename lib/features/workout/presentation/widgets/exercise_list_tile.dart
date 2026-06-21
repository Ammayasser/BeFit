import 'package:befit/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/workout_models.dart';
import 'exercise_gif_image.dart';
import 'workout_difficulty_badge.dart';
import '../../core/workout_colors.dart';

class ExerciseListTile extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;
    final imageUrl = exercise.images.isNotEmpty
        ? exercise.images.first
        : exercise.gifUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * s),
        decoration: BoxDecoration(
          color: WorkoutColors.card(context),
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: WorkoutColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10 * s,
              offset: Offset(0, 4 * s),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * s),
                  bottomLeft: Radius.circular(24 * s),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ExerciseGifImage(
                      imageUrl: imageUrl,
                      width: 96 * s,
                      height: 96 * s,
                      fit: BoxFit.cover,
                      fallback: _fallback(s),
                    ),
                    if (hasVideo)
                      Container(
                        padding: EdgeInsets.all(6 * s),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20 * s,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.montserrat(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontSize: 15 * fs,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8 * s),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (exercise.target != null &&
                                exercise.target!.isNotEmpty) ...[
                              _chip(
                                exercise.target!,
                                primary: true,
                                s: s,
                                fs: fs,
                              ),
                              SizedBox(width: 4 * s),
                            ],
                            if (exercise.difficulty != null &&
                                exercise.difficulty!.isNotEmpty) ...[
                              WorkoutDifficultyBadge(
                                difficulty: exercise.difficulty,
                              ),
                              SizedBox(width: 4 * s),
                            ],
                            if (exercise.isBodyweight == true) ...[
                              _chip('BODYWEIGHT', primary: false, s: s, fs: fs),
                              SizedBox(width: 4 * s),
                            ],
                            if (exercise.equipment != null &&
                                exercise.equipment!.isNotEmpty)
                              _chip(
                                exercise.primaryEquipment,
                                primary: false,
                                s: s,
                                fs: fs,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 16 * s),
                child: Center(
                  child:
                      trailing ??
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1),
                        size: 14 * s,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(double s) => Container(
    width: 96 * s,
    height: 96 * s,
    color: const Color(0xFFF8FAFB),
    alignment: Alignment.center,
    child: Icon(
      Icons.fitness_center_rounded,
      color: const Color(0xFFCBD5E1),
      size: 32 * s,
    ),
  );

  Widget _chip(
    String text, {
    required bool primary,
    required double s,
    required double fs,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
    decoration: BoxDecoration(
      color: primary
          ? const Color(0xFF7CA794).withValues(alpha: 0.1)
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8 * s),
    ),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
        color: primary ? const Color(0xFF5E8A78) : const Color(0xFF64748B),
        fontSize: 9 * fs,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}
