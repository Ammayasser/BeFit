import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/exercise_media.dart';
import 'exercise_video_player.dart';

/// Loads exercise GIFs from the library API or any HTTPS workout cover image.
class ExerciseGifImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const ExerciseGifImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Immediate local asset if provided
    if (imageUrl != null && imageUrl!.startsWith('assets/')) {
      return _wrap(
        Image.asset(imageUrl!, width: width, height: height, fit: fit),
      );
    }

    // 2. Normalize the API URL
    final url = normalizeExerciseMediaUrl(imageUrl);

    // If no URL from API yet, show a clean loading box or the fallback widget
    if (url == null) {
      return _wrap(fallback ?? _defaultFallback(context));
    }

    if (isVideoUrl(url)) {
      return _wrap(
        SizedBox(
          width: width,
          height: height,
          child: ExerciseVideoPlayer(
            videoUrl: url,
            autoPlay: true,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? const Color(0xFF1E293B) : Colors.grey[200]!;

    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
        ),
      ),
      errorWidget: (context, _, _) => fallback ?? _defaultFallback(context),
    );

    return _wrap(image);
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _defaultFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100]!,
    );
  }
}
