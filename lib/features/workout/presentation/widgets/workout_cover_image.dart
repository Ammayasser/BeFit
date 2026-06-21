import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import '../../data/services/workout_cover_resolver.dart';
import '../widgets/exercise_gif_image.dart';

/// Hero / card cover: exercise GIF from library, or stock image, with optional gradient overlay.
///
/// FIX SUMMARY (Bug #1 — Wrong silhouette for male users):
///   The old code passed `gender` down from `NetflixWorkoutSection` → `_WorkoutPoster`
///   → `WorkoutCoverImage`, but the LARGE featured row (`isLarge: true`) was calling
///   `WorkoutCoverImage` WITHOUT passing `gender`, so it always fell back to
///   `assets/images/trainer.png` (a female silhouette). The fix ensures:
///   1. `userGender` is always forwarded by every caller.
///   2. The fallback priority is:  exercise GIF → stock URL → gender asset → trainer.png
///   3. The override logic is clear and exhaustive: any null/empty/generic URL
///      gets replaced with the correct gender asset for the current user.
class WorkoutCoverImage extends StatefulWidget {
  final String? workoutRouteId;
  final String? imageUrl;
  final String? muscleGroup;
  final String? category;

  /// REQUIRED for correct gender fallback. Pass `userProvider.gender` from every call site.
  final String? gender;

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final double overlayOpacity;
  final BoxFit fit;

  const WorkoutCoverImage({
    super.key,
    this.workoutRouteId,
    this.imageUrl,
    this.muscleGroup,
    this.category,
    this.gender, // ← callers must supply this
    this.width,
    this.height,
    this.borderRadius,
    this.gradientColors,
    this.overlayOpacity = 0.55,
    this.fit = BoxFit.cover,
  });

  @override
  State<WorkoutCoverImage> createState() => _WorkoutCoverImageState();
}

class _WorkoutCoverImageState extends State<WorkoutCoverImage> {
  final _resolver = WorkoutCoverResolver();
  String? _resolvedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkoutCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutRouteId != widget.workoutRouteId ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.gender != widget.gender) {
      _load();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Normalises the gender string so comparison is safe regardless of casing.
  bool get _isMale {
    final g = widget.gender?.toLowerCase().trim() ?? '';
    return g == 'male' || g == 'men';
  }

  bool get _isFemale {
    final g = widget.gender?.toLowerCase().trim() ?? '';
    return g == 'female' || g == 'women';
  }

  /// Returns the correct local fallback asset for the current user's gender.
  String get _genderFallbackAsset {
    if (_isMale) return 'assets/images/male.png';
    if (_isFemale) return 'assets/images/female.png';
    return 'assets/images/trainer.png'; // neutral / unknown
  }

  /// Returns true if `url` is a placeholder / opposite-gender asset that should
  /// be replaced with the correct gender asset.
  bool _shouldOverride(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    if (_isMale && url.contains('female')) return true;
    if (_isFemale && url.contains('male') && !url.contains('female')) {
      return true;
    }
    // Generic trainer placeholder → replace with gender-correct one
    if (url == 'assets/images/trainer.png') return true;
    return false;
  }

  // ---------------------------------------------------------------------------
  // Core loading pipeline
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    String? url = widget.imageUrl;

    // Step 1 – Try to resolve a real exercise GIF or stock photo.
    if ((url == null || url.isEmpty) && widget.workoutRouteId != null) {
      url = await _resolver.resolve(
        workoutRouteId: widget.workoutRouteId!,
        muscleGroup: widget.muscleGroup,
        category: widget.category,
      );
    }

    // Step 2 – Gender override: if the resolved URL is wrong/empty, use the
    //          correct gender asset. This is the FIX for the bug in the
    //          screenshots — male users were seeing a female silhouette because
    //          the fallback 'assets/images/trainer.png' is a female figure.
    if (_shouldOverride(url)) {
      url = _genderFallbackAsset;
    }

    // Step 3 – Final safety net (should never be reached after step 2).
    url ??= _genderFallbackAsset;

    if (!mounted) return;
    setState(() {
      _resolvedUrl = url;
      _loading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.zero;
    final gradient =
        widget.gradientColors ??
        [
          Colors.black.withValues(alpha: widget.overlayOpacity * 0.3),
          Colors.black.withValues(alpha: widget.overlayOpacity),
        ];

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_loading)
              Container(color: WorkoutColors.card(context))
            else
              ExerciseGifImage(
                imageUrl: _resolvedUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                borderRadius: radius,
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradient,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
