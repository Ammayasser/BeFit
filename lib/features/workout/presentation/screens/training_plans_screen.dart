import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_decorations.dart';

class TrainingPlansScreen extends StatelessWidget {
  const TrainingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WorkoutColors.onSurface(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Training Programs",
          style: GoogleFonts.montserrat(
            color: WorkoutColors.onSurface(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH.toDouble(),
            vertical: AppSpacing.md.toDouble(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preset Programs Section
              Text(
                "Explore Featured Programs",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: WorkoutColors.onSurface(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildPresetProgramTile(
                context,
                title: "Hypertrophy Push-Pull-Legs (PPL)",
                duration: "6 Weeks • 5 days/wk",
                description:
                    "Maximize muscle hypertrophy targeting chest, back, and leg compartments separately.",
                difficulty: "Intermediate",
                diffColor: AppColors.diffIntermediate,
              ),
              _buildPresetProgramTile(
                context,
                title: "Lean & Toned Bodyweight",
                duration: "4 Weeks • 3 days/wk",
                description:
                    "High-intensity home circuits focused on lean definition and cardio conditioning.",
                difficulty: "Beginner",
                diffColor: AppColors.diffBeginner,
              ),
              _buildPresetProgramTile(
                context,
                title: "Strength & Power Builder",
                duration: "8 Weeks • 4 days/wk",
                description:
                    "Heavy barbell compound loading focused on developing raw maximum power outputs.",
                difficulty: "Advanced",
                diffColor: AppColors.diffAdvanced,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetProgramTile(
    BuildContext context, {
    required String title,
    required String duration,
    required String description,
    required String difficulty,
    required Color diffColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: WorkoutColors.onSurface(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  difficulty,
                  style: GoogleFonts.montserrat(
                    color: diffColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: GoogleFonts.montserrat(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Preset programs coming soon!"),
                    backgroundColor: WorkoutColors.surfaceMuted(context),
                  ),
                );
              },
              child: Text(
                "Enroll Program",
                style: GoogleFonts.montserrat(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
