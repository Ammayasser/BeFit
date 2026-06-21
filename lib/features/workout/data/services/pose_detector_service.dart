// lib/features/workout/data/services/pose_detector_service.dart
//
// On-device pose detection using Google ML Kit.
// This service wraps the PoseDetector and handles:
//   • Converting CameraImage → InputImage for ML Kit
//   • Managing the PoseDetector lifecycle
//   • Mapping ML Kit PoseLandmark → our own PoseLandmarkType enum
//   • Handling rotation for front/back camera
//
// NO NETWORK REQUIRED — everything runs on-device.

import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml;

import '../models/exercise_definitions.dart';

/// A single detected landmark from pose detection.
class DetectedLandmark {
  final PoseLandmarkType type;
  final double x; // Normalized 0-1
  final double y; // Normalized 0-1
  final double likelihood; // 0-1 confidence

  const DetectedLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.likelihood,
  });
}

/// Result from a single frame of pose detection.
class PoseDetectionResult {
  final List<DetectedLandmark> landmarks;
  final bool poseDetected;
  final Size imageSize; // Pixel dimensions of the input image

  const PoseDetectionResult({
    required this.landmarks,
    required this.poseDetected,
    required this.imageSize,
  });

  /// Get a specific landmark by type, or null if not detected.
  DetectedLandmark? getLandmark(PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((l) => l.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Get all landmarks as a map for O(1) lookup.
  Map<PoseLandmarkType, DetectedLandmark> get landmarkMap {
    return {for (final l in landmarks) l.type: l};
  }
}

class PoseDetectorService {
  late ml.PoseDetector _poseDetector;
  bool _isInitialized = false;

  /// Get initialization status.
  bool get isInitialized => _isInitialized;

  /// Initialize the on-device PoseDetector.
  ///
  /// ML Kit Pose Detection has two modes:
  ///   • stream: optimized for video frames (our use case)
  ///   • single: optimized for individual images
  ///
  /// We use stream mode because we're processing a continuous camera feed.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final options = ml.PoseDetectorOptions(
      mode: ml.PoseDetectionMode.stream,
      model: ml.PoseDetectionModel.accurate,
    );

    _poseDetector = ml.PoseDetector(options: options);
    _isInitialized = true;
    debugPrint(
      '[PoseDetectorService] Initialized with stream mode + accurate model',
    );
  }

  /// Process a [CameraImage] frame and return detected pose landmarks.
  ///
  /// [cameraImage] - The raw frame from CameraController.startImageStream
  /// [sensorOrientation] - Device sensor orientation (0, 90, 180, 270)
  /// [isFrontCamera] - Whether using the front-facing camera
  /// [imageWidth] - Width of the camera preview
  /// [imageHeight] - Height of the camera preview
  Future<PoseDetectionResult> processFrame(
    CameraImage cameraImage, {
    required int sensorOrientation,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (!_isInitialized) {
      return const PoseDetectionResult(
        landmarks: [],
        poseDetected: false,
        imageSize: Size(0, 0),
      );
    }

    try {
      // ── Step 1: Build InputImage from CameraImage ────────────────────────
      //
      // For stream mode, we need to provide the plane data, not a file or bytes.
      // ML Kit handles YUV420 and BGRA8888 formats natively on most devices.

      final ml.InputImageRotation rotation = _computeInputImageRotation(
        sensorOrientation: sensorOrientation,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      final inputImage = ml.InputImage.fromBytes(
        bytes: Platform.isAndroid
            ? _convertYUV420ToNV21(cameraImage)
            : _concatenatePlanes(cameraImage),
        metadata: ml.InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation,
          format: Platform.isAndroid
              ? ml.InputImageFormat.nv21
              : _mapImageFormat(cameraImage.format.group),
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );

      // ── Step 2: Run pose detection ───────────────────────────────────────
      final List<ml.Pose> poses = await _poseDetector.processImage(inputImage);

      // ── Step 3: Convert ML Kit Pose → our DetectedLandmark list ─────────
      if (poses.isEmpty) {
        return PoseDetectionResult(
          landmarks: const [],
          poseDetected: false,
          imageSize: Size(imageWidth.toDouble(), imageHeight.toDouble()),
        );
      }

      final pose = poses.first;
      final landmarks = _convertPoseLandmarks(pose, imageWidth, imageHeight, rotation);

      return PoseDetectionResult(
        landmarks: landmarks,
        poseDetected: true,
        imageSize: Size(imageWidth.toDouble(), imageHeight.toDouble()),
      );
    } catch (e) {
      debugPrint('[PoseDetectorService] processFrame error: $e');
      return const PoseDetectionResult(
        landmarks: [],
        poseDetected: false,
        imageSize: Size(0, 0),
      );
    }
  }

  /// Process an [InputImage] directly (for cases where the caller has
  /// already prepared the input image, e.g., from a still photo).
  Future<PoseDetectionResult> processInputImage(
    ml.InputImage inputImage, {
    required int previewWidth,
    required int previewHeight,
    ml.InputImageRotation rotation = ml.InputImageRotation.rotation0deg,
  }) async {
    if (!_isInitialized) {
      return const PoseDetectionResult(
        landmarks: [],
        poseDetected: false,
        imageSize: Size(0, 0),
      );
    }

    try {
      final List<ml.Pose> poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return PoseDetectionResult(
          landmarks: const [],
          poseDetected: false,
          imageSize: Size(previewWidth.toDouble(), previewHeight.toDouble()),
        );
      }

      final pose = poses.first;
      final landmarks = _convertPoseLandmarks(
        pose,
        previewWidth,
        previewHeight,
        rotation,
      );

      return PoseDetectionResult(
        landmarks: landmarks,
        poseDetected: true,
        imageSize: Size(previewWidth.toDouble(), previewHeight.toDouble()),
      );
    } catch (e) {
      debugPrint('[PoseDetectorService] processInputImage error: $e');
      return const PoseDetectionResult(
        landmarks: [],
        poseDetected: false,
        imageSize: Size(0, 0),
      );
    }
  }

  /// Release resources.
  void dispose() {
    if (!_isInitialized) return; // Safe to call multiple times
    _poseDetector.close();
    _isInitialized = false;
    debugPrint('[PoseDetectorService] Disposed');
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────

  /// Compute the InputImageRotation based on sensor orientation and camera direction.
  ///
  /// This is critical — wrong rotation means the AI sees the body sideways.
  ml.InputImageRotation _computeInputImageRotation({
    required int sensorOrientation,
    required String platform,
  }) {
    // BUG #1 FIX: Do NOT reverse rotation for front camera.
    // ML Kit's InputImageRotation is the physical sensor orientation used
    // to rotate the raw buffer to upright before inference. It is the same
    // for both front and back cameras. Mirroring for display is handled
    // separately by the SkeletonPainter (x = 1.0 - x).
    //
    // BUG #8 FIX: iOS frames are NOT always upright — use sensorOrientation
    // directly instead of hardcoding rotation0deg.

    switch (sensorOrientation) {
      case 0:
        return ml.InputImageRotation.rotation0deg;
      case 90:
        return ml.InputImageRotation.rotation90deg;
      case 180:
        return ml.InputImageRotation.rotation180deg;
      case 270:
        return ml.InputImageRotation.rotation270deg;
      default:
        return ml.InputImageRotation.rotation0deg;
    }
  }

  /// Concatenate all plane bytes for ML Kit input.
  ///
  /// ML Kit's `InputImage.fromBytes` expects all planes concatenated.
  Uint8List _concatenatePlanes(CameraImage image) {
    final allBytes = <int>[];
    for (final plane in image.planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  /// Converts a YUV420 CameraImage into a single NV21 byte buffer for Android ML Kit.
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final bytesPerPixel = vPlane.bytesPerPixel ?? 1;

    if (bytesPerPixel == 2) {
      // Highly optimized path: just copy Y and then copy the V buffer directly
      // since vBuffer already contains interleaved V and U bytes (VU VU VU...).
      final nv21 = Uint8List(yBuffer.length + vBuffer.length);
      nv21.setRange(0, yBuffer.length, yBuffer);
      nv21.setRange(yBuffer.length, nv21.length, vBuffer);
      return nv21;
    } else {
      // Planar YUV420 (bytesPerPixel == 1): manually interleave V and U.
      final nv21 = Uint8List((width * height * 1.5).toInt());
      nv21.setRange(0, yBuffer.length, yBuffer);
      int id = yBuffer.length;
      for (int i = 0; i < uBuffer.length; i++) {
        nv21[id++] = vBuffer[i]; // V
        nv21[id++] = uBuffer[i]; // U
      }
      return nv21;
    }
  }

  /// Map camera ImageFormatGroup to ML Kit InputImageFormat.
  ml.InputImageFormat _mapImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
      case ImageFormatGroup.yuv420:
        return ml.InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return ml.InputImageFormat.bgra8888;
      case ImageFormatGroup.nv21:
        return ml.InputImageFormat.nv21;
      case ImageFormatGroup.jpeg:
        return ml.InputImageFormat.yuv420; // Fallback
      default:
        return ml.InputImageFormat.yuv420; // Safe default
    }
  }

  /// Convert ML Kit Pose landmarks to our DetectedLandmark list.
  ///
  /// ML Kit provides landmarks with pixel coordinates. We normalize them
  /// to 0-1 range so the UI layer can scale to any screen size.
  List<DetectedLandmark> _convertPoseLandmarks(
    ml.Pose pose,
    int imageWidth,
    int imageHeight,
    ml.InputImageRotation rotation,
  ) {
    final landmarks = <DetectedLandmark>[];

    // BUG #2 FIX: When ML Kit processes an image with rotation 90/270, it
    // rotates the buffer internally and returns landmarks in the rotated
    // coordinate space. We must swap width/height for normalization.
    final bool isRotated = rotation == ml.InputImageRotation.rotation90deg ||
        rotation == ml.InputImageRotation.rotation270deg;
    final double normW = isRotated ? imageHeight.toDouble() : imageWidth.toDouble();
    final double normH = isRotated ? imageWidth.toDouble() : imageHeight.toDouble();

    // Map ML Kit landmark types to our enum
    final mlKitLandmarks = {
      PoseLandmarkType.nose: pose.landmarks[ml.PoseLandmarkType.nose],
      PoseLandmarkType.leftEyeInner: pose.landmarks[ml.PoseLandmarkType.leftEyeInner],
      PoseLandmarkType.leftEye: pose.landmarks[ml.PoseLandmarkType.leftEye],
      PoseLandmarkType.leftEyeOuter: pose.landmarks[ml.PoseLandmarkType.leftEyeOuter],
      PoseLandmarkType.rightEyeInner:
          pose.landmarks[ml.PoseLandmarkType.rightEyeInner],
      PoseLandmarkType.rightEye: pose.landmarks[ml.PoseLandmarkType.rightEye],
      PoseLandmarkType.rightEyeOuter:
          pose.landmarks[ml.PoseLandmarkType.rightEyeOuter],
      PoseLandmarkType.leftEar: pose.landmarks[ml.PoseLandmarkType.leftEar],
      PoseLandmarkType.rightEar: pose.landmarks[ml.PoseLandmarkType.rightEar],
      PoseLandmarkType.leftMouth: pose.landmarks[ml.PoseLandmarkType.leftMouth],
      PoseLandmarkType.rightMouth: pose.landmarks[ml.PoseLandmarkType.rightMouth],
      PoseLandmarkType.leftShoulder: pose.landmarks[ml.PoseLandmarkType.leftShoulder],
      PoseLandmarkType.rightShoulder:
          pose.landmarks[ml.PoseLandmarkType.rightShoulder],
      PoseLandmarkType.leftElbow: pose.landmarks[ml.PoseLandmarkType.leftElbow],
      PoseLandmarkType.rightElbow: pose.landmarks[ml.PoseLandmarkType.rightElbow],
      PoseLandmarkType.leftWrist: pose.landmarks[ml.PoseLandmarkType.leftWrist],
      PoseLandmarkType.rightWrist: pose.landmarks[ml.PoseLandmarkType.rightWrist],
      PoseLandmarkType.leftPinky: pose.landmarks[ml.PoseLandmarkType.leftPinky],
      PoseLandmarkType.rightPinky: pose.landmarks[ml.PoseLandmarkType.rightPinky],
      PoseLandmarkType.leftIndex: pose.landmarks[ml.PoseLandmarkType.leftIndex],
      PoseLandmarkType.rightIndex:
          pose.landmarks[ml.PoseLandmarkType.rightIndex],
      PoseLandmarkType.leftThumb: pose.landmarks[ml.PoseLandmarkType.leftThumb],
      PoseLandmarkType.rightThumb: pose.landmarks[ml.PoseLandmarkType.rightThumb],
      PoseLandmarkType.leftHip: pose.landmarks[ml.PoseLandmarkType.leftHip],
      PoseLandmarkType.rightHip: pose.landmarks[ml.PoseLandmarkType.rightHip],
      PoseLandmarkType.leftKnee: pose.landmarks[ml.PoseLandmarkType.leftKnee],
      PoseLandmarkType.rightKnee: pose.landmarks[ml.PoseLandmarkType.rightKnee],
      PoseLandmarkType.leftAnkle: pose.landmarks[ml.PoseLandmarkType.leftAnkle],
      PoseLandmarkType.rightAnkle: pose.landmarks[ml.PoseLandmarkType.rightAnkle],
      PoseLandmarkType.leftHeel: pose.landmarks[ml.PoseLandmarkType.leftHeel],
      PoseLandmarkType.rightHeel: pose.landmarks[ml.PoseLandmarkType.rightHeel],
      PoseLandmarkType.leftFootIndex:
          pose.landmarks[ml.PoseLandmarkType.leftFootIndex],
      PoseLandmarkType.rightFootIndex:
          pose.landmarks[ml.PoseLandmarkType.rightFootIndex],
    };

    for (final entry in mlKitLandmarks.entries) {
      final lm = entry.value;
      if (lm != null) {
        landmarks.add(
          DetectedLandmark(
            type: entry.key,
            x: lm.x / normW,
            y: lm.y / normH,
            likelihood: lm.likelihood,
          ),
        );
      }
    }

    return landmarks;
  }
}
