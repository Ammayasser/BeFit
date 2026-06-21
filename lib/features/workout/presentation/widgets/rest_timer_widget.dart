import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/constants/app_colors.dart';

class RestTimerWidget extends StatelessWidget {
  final int secondsTotal;
  final int secondsRemaining;
  final VoidCallback onSkip;
  final VoidCallback onAddTime;
  final VoidCallback onSubtractTime;

  const RestTimerWidget({
    super.key,
    required this.secondsTotal,
    required this.secondsRemaining,
    required this.onSkip,
    required this.onAddTime,
    required this.onSubtractTime,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final double percent = secondsTotal > 0
        ? (secondsRemaining / secondsTotal).clamp(0.0, 1.0)
        : 0.0;
    final Color timerColor = secondsRemaining <= 10
        ? AppColors.accentOrange
        : AppColors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "RESTING",
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          // Circular Countdown Timer
          CircularPercentIndicator(
            radius: 100.0,
            lineWidth: 8.0,
            percent: percent,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: WorkoutColors.border(context),
            progressColor: timerColor,
            animateFromLastPercent: true,
            center: Text(
              _formatTime(secondsRemaining),
              style: GoogleFonts.jetBrainsMono(
                color: WorkoutColors.onSurface(context),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Time Adjustments
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: onSubtractTime,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: WorkoutColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "-10s",
                  style: GoogleFonts.montserrat(
                    color: WorkoutColors.onSurfaceMuted(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: onAddTime,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: WorkoutColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "+10s",
                  style: GoogleFonts.montserrat(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Skip Action
          TextButton(
            onPressed: onSkip,
            child: Text(
              "Skip Rest",
              style: GoogleFonts.montserrat(
                color: WorkoutColors.onSurfaceMuted(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
