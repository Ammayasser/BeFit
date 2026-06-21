import 'dart:convert';
import '../../../core/constants/api_constants.dart';

/// Normalizes exercise media URLs for [CachedNetworkImage].
String? normalizeExerciseMediaUrl(String? raw) {
  if (raw == null) return null;
  var trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  // Intercept and fix legacy domains if they leak from old data or backends
  if (trimmed.contains('workoutx.com') ||
      trimmed.contains('exercisedb.p.rapidapi.com') ||
      trimmed.contains('edb-gifs.com')) {
    // Attempt to keep the path but change the domain to the target API
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      // Many old APIs used '0025.gif', new one uses IDs or JPGs
      // We'll try to let the Widget handle the error or fallback
      return '${ApiConstants.exerciseApiBase}/exercises/$lastSegment';
    }
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('assets/')) {
    return trimmed;
  }
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  // The new API uses relative paths if not absolute
  if (trimmed.startsWith('/')) {
    return '${ApiConstants.exerciseApiBase}$trimmed';
  }
  return '${ApiConstants.exerciseApiBase}/$trimmed';
}

/// Checks if a media URL represents a video file (MP4).
bool isVideoUrl(String? url) {
  if (url == null) return false;
  final clean = url.trim().toLowerCase();
  return clean.endsWith('.mp4') || 
         clean.contains('.mp4?') ||
         clean.endsWith('.mov') ||
         clean.endsWith('.webm');
}

/// Reads GIF / image URL from Exercise API or SQLite row JSON.

String? parseExerciseGifFromJson(Map<String, dynamic> json) {
  final all = parseExerciseImagesFromJson(json);
  return all.isNotEmpty ? all.first : null;
}

/// Reads all image URLs from Exercise API or SQLite row JSON.
List<String> parseExerciseImagesFromJson(Map<String, dynamic> json) {
  const keys = [
    'images',
    'gifUrl',
    'gif_url',
    'gif',
    'imageUrl',
    'image_url',
    'image',
    'animationUrl',
    'animation_url',
    'thumbnail',
    'mediaUrl',
    'media_url',
  ];
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      if (value is List) {
        return value
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .map((e) => normalizeExerciseMediaUrl(e.toString())!)
            .toList();
      } else if (value is String) {
        // Might be a JSON string of a list if coming from SQLite
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .map((e) => normalizeExerciseMediaUrl(e.toString())!)
                .toList();
          }
        } catch (_) {}

        if (value.trim().isNotEmpty) {
          return [normalizeExerciseMediaUrl(value)!];
        }
      }
    }
  }
  return [];
}

/// Stock cover when library has no GIF yet (category / muscle based).
String stockWorkoutCoverUrl({String? name, String? muscleGroup, String? category}) {
  final query = '${name ?? ''} ${muscleGroup ?? ''} ${category ?? ''}'.toLowerCase();
  
  // High-Accuracy Movement Mapping
  if (query.contains('squat')) {
    return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80&auto=format'; // Specific Squat
  }
  if (query.contains('bench press') || query.contains('chest press')) {
    return 'https://images.unsplash.com/photo-1534367958380-a0151123440a?w=800&q=80&auto=format'; // Specific Bench
  }
  if (query.contains('deadlift')) {
    return 'https://images.unsplash.com/photo-1603281123168-9ea14e35b21f?w=800&q=80&auto=format'; // Specific Deadlift
  }
  if (query.contains('push up') || query.contains('pushup')) {
    return 'https://images.unsplash.com/photo-1598971639058-fab3c023d60e?w=800&q=80&auto=format'; // Pushup
  }
  if (query.contains('row') || query.contains('pull up') || query.contains('pullup')) {
    return 'https://images.unsplash.com/photo-1434682881908-b43d3f7d6b3e?w=800&q=80&auto=format'; // Back movement
  }
  if (query.contains('curl')) {
    return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80&auto=format'; // Bicep Curl
  }
  if (query.contains('shoulder press') || query.contains('military press')) {
    return 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=800&q=80&auto=format'; // Shoulder Press
  }
  if (query.contains('crunch') || query.contains('abs') || query.contains('plank')) {
    return 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800&q=80&auto=format'; // Core
  }
  if (query.contains('hiit') || query.contains('burpee')) {
    return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80&auto=format'; // High intensity
  }
  
  // Broad Muscle Group Fallbacks
  if (query.contains('chest')) return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50e?w=800&q=80&auto=format';
  if (query.contains('leg')) return 'https://images.unsplash.com/photo-1434682881908-b43d3f7d6b3e?w=800&q=80&auto=format';
  if (query.contains('arm')) return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80&auto=format';
  
  // Ultimate professional trainer fallback
  return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80&auto=format';
}
