// lib/core/utils/image_utils.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Converts a [CameraImage] to a Base64 encoded JPEG string.
  ///
  /// [sensorOrientation] is needed to rotate the image correctly.
  /// [isFrontCamera] is needed to flip the image horizontally (mirror).
  ///
  /// Target output: ~320px wide, JPEG quality 75 — optimal for pose detection
  /// APIs: small enough for fast upload, large enough for accurate inference.
  static String? convertCameraImageToBase64(
    CameraImage image, {
    int sensorOrientation = 0,
    bool isFrontCamera = false,
  }) {
    try {
      img.Image? converted;

      if (image.format.group == ImageFormatGroup.yuv420) {
        converted = _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        converted = _convertBGRA8888(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        converted = _convertYUV420(image); // NV21 is close enough for this path
      }

      if (converted == null) return null;

      // ── Step 1: Rotate & Flip BEFORE resize (correct orientation first) ──
      //
      // Android sensor orientation quirks:
      //  - Back camera: sensor is rotated 90° clockwise from natural → rotate +90
      //  - Front camera: sensor is rotated 270° (or -90°) → rotate -90 THEN flip
      //
      // The previous code rotated AFTER resize, on the already-small image —
      // that is fine for speed, but the rotation DIRECTION was wrong for the
      // front camera, causing the AI to see the body sideways (e.g. a Bicep
      // Curl looked like a Sit-Up because the person appeared horizontal).
      img.Image oriented = converted;

      if (sensorOrientation == 90) {
        // Most Android back cameras
        oriented = img.copyRotate(converted, angle: 90);
      } else if (sensorOrientation == 270) {
        // Android front cameras (common value)
        oriented = img.copyRotate(converted, angle: -90);
      } else if (sensorOrientation == 180) {
        oriented = img.copyRotate(converted, angle: 180);
      }
      // sensorOrientation == 0: already upright (most iOS cameras)

      // Front cameras produce a mirrored image — flip horizontally so the
      // AI model sees the same orientation it was trained on.
      if (isFrontCamera) {
        oriented = img.copyFlip(oriented, direction: img.FlipDirection.horizontal);
      }

      // ── Step 2: Resize to target width (480px max for better AI accuracy) ──
      //
      // 480px gives the pose model enough resolution to distinguish exercises
      // while keeping payload small. We only resize if actually larger.
      img.Image resized;
      const int targetWidth = 480;

      if (oriented.width > targetWidth) {
        resized = img.copyResize(
          oriented,
          width: targetWidth,
          interpolation: img.Interpolation.linear, // Slightly better than nearest
        );
      } else {
        resized = oriented; // Already small enough — skip resize entirely
      }

      // ── Step 3: Encode as JPEG at quality 75 ──
      //
      // Quality 75 is the sweet spot: ~40% larger than quality 50 but
      // preserves body contours and joint angles that the AI model relies on.
      // At 320-480px this still produces a very small payload (~15-25 KB).
      final Uint8List jpeg =
          Uint8List.fromList(img.encodeJpg(resized, quality: 75));
      return base64Encode(jpeg);
    } catch (e) {
      // Use debugPrint-style to avoid polluting release logs
      assert(() {
        // ignore: avoid_print
        print('[ImageUtils] convertCameraImageToBase64 error: $e');
        return true;
      }());
      return null;
    }
  }

  // ── YUV420 → RGB conversion ──────────────────────────────────────────────
  //
  // Uses integer math (<<10 fixed-point) for speed, following ITU-R BT.601.
  // Handles planes that may have non-1 pixel strides (as on many Android phones).
  static img.Image _convertYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List yBytes = yPlane.bytes;
    final Uint8List uBytes = uPlane.bytes;
    final Uint8List vBytes = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x * yPixelStride;
        final int uvIndex = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;

        // Guard against out-of-bounds (can happen on some device camera configs)
        if (yIndex >= yBytes.length ||
            uvIndex >= uBytes.length ||
            uvIndex >= vBytes.length) {
          continue;
        }

        final int yVal = yBytes[yIndex] & 0xFF;
        final int uVal = (uBytes[uvIndex] & 0xFF) - 128;
        final int vVal = (vBytes[uvIndex] & 0xFF) - 128;

        // ITU-R BT.601 YCbCr → RGB (integer fixed-point, ×1024 scale)
        final int r = (yVal + ((vVal * 1436) >> 10)).clamp(0, 255);
        final int g = (yVal - ((uVal * 352 + vVal * 731) >> 10)).clamp(0, 255);
        final int b = (yVal + ((uVal * 1814) >> 10)).clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  static img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }
}
