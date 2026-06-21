// lib/features/workout/data/models/exercise_definitions.dart
//
// Comprehensive exercise definitions for on-device pose-based tracking.
// Each exercise specifies:
//   • Which joints/angles drive the rep counter
//   • Threshold angles for phase detection (top/bottom of movement)
//   • Form-quality rules with ideal ranges
//   • Coaching tips for common mistakes
//
// The angle calculations are done in ExerciseAnalyzerService using
// the 33 landmarks from Google ML Kit Pose Detection.

/// Represents a single exercise that can be tracked with pose estimation.
class ExerciseDefinition {
  final String key;
  final String displayName;
  final String category;
  final String iconEmoji;
  final ExerciseType type;
  final AngleConfig primaryAngle;
  final List<AngleConfig> secondaryAngles;
  final List<FormRule> formRules;
  final List<String> tips;
  final List<String> commonMistakes;
  final double difficultyScore; // 1.0 (easy) to 5.0 (hard)

  const ExerciseDefinition({
    required this.key,
    required this.displayName,
    required this.category,
    required this.iconEmoji,
    required this.type,
    required this.primaryAngle,
    this.secondaryAngles = const [],
    this.formRules = const [],
    this.tips = const [],
    this.commonMistakes = const [],
    this.difficultyScore = 2.0,
  });
}

/// Whether the exercise is rep-based or hold-based.
enum ExerciseType { reps, hold }

/// Which three joints form the angle used for rep counting / phase detection.
///
/// [startJoint] and [endJoint] are the outer joints;
/// [midJoint] is the vertex (the joint whose angle we measure).
///
/// Example: For a bicep curl, we measure the elbow angle:
///   startJoint = shoulder, midJoint = elbow, endJoint = wrist
class AngleConfig {
  final PoseLandmarkType startJoint;
  final PoseLandmarkType midJoint;
  final PoseLandmarkType endJoint;
  final double topAngle; // Angle at the "rest" position (rep start)
  final double bottomAngle; // Angle at the "peak contraction" position
  final AngleDirection
  direction; // Does the angle open or close during eccentric?

  const AngleConfig({
    required this.startJoint,
    required this.midJoint,
    required this.endJoint,
    required this.topAngle,
    required this.bottomAngle,
    this.direction = AngleDirection.closing,
  });
}

/// Direction of angle change during the eccentric (lowering) phase.
enum AngleDirection {
  closing, // Angle decreases (e.g., bicep curl: elbow goes from ~170° to ~40°)
  opening, // Angle increases (e.g., squat: knee goes from ~170° to ~90°)
}

/// A form-quality rule that checks a specific joint angle or alignment.
class FormRule {
  final String id;
  final String name;
  final String tipWhenViolated;
  final RuleType type;
  final PoseLandmarkType jointA;
  final PoseLandmarkType jointB;
  final PoseLandmarkType? jointC; // Only for angle rules
  final double? idealMin;
  final double? idealMax;
  final double
  weight; // How much this rule contributes to overall quality (0-1)

  /// Optional: which exercise phases this rule should be evaluated in.
  /// Uses phase name strings ('idle', 'top', 'descending', 'bottom', 'ascending').
  /// If null, the rule is evaluated in ALL phases.
  final Set<String>? activePhases;

  const FormRule({
    required this.id,
    required this.name,
    required this.tipWhenViolated,
    required this.type,
    required this.jointA,
    required this.jointB,
    this.jointC,
    this.idealMin,
    this.idealMax,
    this.weight = 1.0,
    this.activePhases,
  });
}

enum RuleType {
  angle, // Joint angle between A-B-C must be in [idealMin, idealMax]
  alignment, // A and B must be horizontally/vertically aligned
  symmetry, // Left and right joints must mirror each other
}

/// All 33 ML Kit pose landmark types, mirroring the Google ML Kit enum.
/// We define our own enum so the data layer has zero dependency on the
/// ML Kit package — the service layer maps between them.
enum PoseLandmarkType {
  nose,
  leftEyeInner,
  leftEye,
  leftEyeOuter,
  rightEyeInner,
  rightEye,
  rightEyeOuter,
  leftEar,
  rightEar,
  leftMouth,
  rightMouth,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftPinky,
  rightPinky,
  leftIndex,
  rightIndex,
  leftThumb,
  rightThumb,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

// ─── Exercise Registry ────────────────────────────────────────────────────────

class ExerciseRegistry {
  ExerciseRegistry._();

  static final List<ExerciseDefinition> all = [
    // ═══════════════════════════════════════════════════════════════════════════
    // PUSH EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'push_up',
      displayName: 'Push-Up',
      category: 'Chest',
      iconEmoji: '💪',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftShoulder,
        midJoint: PoseLandmarkType.leftElbow,
        endJoint: PoseLandmarkType.leftWrist,
        topAngle: 160, // Arms extended (up position)
        bottomAngle: 70, // Chest near floor (down position)
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        // Body alignment: shoulder-hip-knee should stay ~180°
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftHip,
          endJoint: PoseLandmarkType.leftKnee,
          topAngle: 170,
          bottomAngle: 170,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'push_up_body_align',
          name: 'Body Alignment',
          tipWhenViolated:
              'Keep your body straight — avoid sagging hips or piking up',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          jointC: PoseLandmarkType.leftKnee,
          idealMin: 155,
          idealMax: 190,
          weight: 0.5,
        ),
        FormRule(
          id: 'push_up_symmetry',
          name: 'Arm Symmetry',
          tipWhenViolated:
              'Lower evenly on both sides — don\'t shift weight to one arm',
          type: RuleType.symmetry,
          jointA: PoseLandmarkType.leftElbow,
          jointB: PoseLandmarkType.rightElbow,
          weight: 0.3,
        ),
      ],
      tips: [
        'Keep your core tight and body in a straight line',
        'Lower until your chest nearly touches the ground',
        'Exhale as you push up, inhale as you lower',
      ],
      commonMistakes: [
        'Sagging hips — engage your core',
        'Flaring elbows — keep them at ~45° from your body',
        'Partial range of motion — go all the way down',
      ],
      difficultyScore: 2.0,
    ),

    ExerciseDefinition(
      key: 'shoulder_press',
      displayName: 'Shoulder Press',
      category: 'Shoulders',
      iconEmoji: '🎯',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftShoulder,
        endJoint: PoseLandmarkType.leftElbow,
        topAngle: 165, // Arms extended overhead
        bottomAngle: 80, // Elbows at ~90° (starting position)
        direction: AngleDirection.opening,
      ),
      secondaryAngles: [
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftElbow,
          endJoint: PoseLandmarkType.leftWrist,
          topAngle: 170,
          bottomAngle: 90,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'shoulder_press_torso',
          name: 'Torso Stability',
          tipWhenViolated:
              'Keep your torso upright — avoid leaning back excessively',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.4,
        ),
      ],
      tips: [
        'Press overhead until arms are fully extended',
        'Keep your core engaged to protect your lower back',
        'Lower the weight with control to shoulder level',
      ],
      commonMistakes: [
        'Leaning back too far — reduces shoulder engagement',
        'Not locking out at the top',
        'Using momentum instead of controlled movement',
      ],
      difficultyScore: 2.5,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // PULL EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'bicep_curl',
      displayName: 'Bicep Curl',
      category: 'Arms',
      iconEmoji: '💪',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftShoulder,
        midJoint: PoseLandmarkType.leftElbow,
        endJoint: PoseLandmarkType.leftWrist,
        topAngle: 165, // Arms extended (bottom of curl)
        bottomAngle: 40, // Fully curled (top of curl)
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        // Track right arm too for symmetry
        AngleConfig(
          startJoint: PoseLandmarkType.rightShoulder,
          midJoint: PoseLandmarkType.rightElbow,
          endJoint: PoseLandmarkType.rightWrist,
          topAngle: 165,
          bottomAngle: 40,
          direction: AngleDirection.closing,
        ),
      ],
      formRules: [
        FormRule(
          id: 'curl_upper_arm_still',
          name: 'Upper Arm Stability',
          tipWhenViolated:
              'Keep your upper arm still — don\'t swing your elbow forward',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftElbow,
          weight: 0.5,
        ),
        FormRule(
          id: 'curl_symmetry',
          name: 'Arm Symmetry',
          tipWhenViolated: 'Curl both arms evenly — one side is working harder',
          type: RuleType.symmetry,
          jointA: PoseLandmarkType.leftElbow,
          jointB: PoseLandmarkType.rightElbow,
          weight: 0.3,
        ),
      ],
      tips: [
        'Keep your elbows pinned to your sides',
        'Squeeze at the top for a full contraction',
        'Lower slowly — don\'t just drop the weight',
      ],
      commonMistakes: [
        'Swinging the body to generate momentum',
        'Moving elbows forward instead of isolating biceps',
        'Partial range — fully extend and fully contract',
      ],
      difficultyScore: 1.5,
    ),

    ExerciseDefinition(
      key: 'lat_pulldown',
      displayName: 'Lat Pulldown',
      category: 'Back',
      iconEmoji: '🔙',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftShoulder,
        endJoint: PoseLandmarkType.leftElbow,
        topAngle: 160, // Arms extended overhead
        bottomAngle: 80, // Pulled down to chest
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [],
      formRules: [
        FormRule(
          id: 'pulldown_torso',
          name: 'Torso Position',
          tipWhenViolated:
              'Lean back slightly but keep your torso stable — don\'t rock',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.4,
        ),
      ],
      tips: [
        'Pull the bar down to your upper chest',
        'Squeeze your shoulder blades together at the bottom',
        'Return slowly with control',
      ],
      commonMistakes: [
        'Leaning too far back — turns it into a row',
        'Pulling behind the neck — risk of shoulder injury',
        'Using momentum instead of lat strength',
      ],
      difficultyScore: 2.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // LEG EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'squat',
      displayName: 'Squat',
      category: 'Legs',
      iconEmoji: '🦵',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftKnee,
        endJoint: PoseLandmarkType.leftAnkle,
        topAngle: 170, // Standing (legs straight)
        bottomAngle: 85, // Bottom of squat (thighs parallel or below)
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        // Hip angle: shoulder-hip-knee
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftHip,
          endJoint: PoseLandmarkType.leftKnee,
          topAngle: 175,
          bottomAngle: 80,
          direction: AngleDirection.closing,
        ),
      ],
      formRules: [
        FormRule(
          id: 'squat_knee_tracking',
          name: 'Knee Tracking',
          tipWhenViolated:
              'Keep your knees in line with your toes — don\'t let them cave inward',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftKnee,
          jointB: PoseLandmarkType.leftAnkle,
          weight: 0.35,
        ),
        FormRule(
          id: 'squat_depth',
          name: 'Squat Depth',
          tipWhenViolated:
              'Go deeper — aim for thighs parallel to the ground for full benefit',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftHip,
          jointB: PoseLandmarkType.leftKnee,
          jointC: PoseLandmarkType.leftAnkle,
          idealMin: 70,
          idealMax: 110,
          weight: 0.35,
          activePhases: {'bottom', 'descending'},
        ),
        FormRule(
          id: 'squat_torso',
          name: 'Torso Upright',
          tipWhenViolated:
              'Keep your chest up — don\'t round your back forward',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          jointC: PoseLandmarkType.leftKnee,
          idealMin: 50,
          idealMax: 120,
          weight: 0.3,
          activePhases: {'bottom', 'descending', 'ascending'},
        ),
      ],
      tips: [
        'Break at the hips first, then bend the knees',
        'Keep your weight on your heels',
        'Drive through your heels to stand back up',
      ],
      commonMistakes: [
        'Knees caving inward — push them out over your toes',
        'Rounding the lower back — keep chest up and core tight',
        'Not hitting depth — go at least to parallel',
      ],
      difficultyScore: 2.5,
    ),

    ExerciseDefinition(
      key: 'lunge',
      displayName: 'Lunge',
      category: 'Legs',
      iconEmoji: '🦿',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftKnee,
        endJoint: PoseLandmarkType.leftAnkle,
        topAngle: 170, // Standing
        bottomAngle: 85, // Lunge position
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftHip,
          endJoint: PoseLandmarkType.leftKnee,
          topAngle: 175,
          bottomAngle: 90,
          direction: AngleDirection.closing,
        ),
      ],
      formRules: [
        FormRule(
          id: 'lunge_knee_over_toe',
          name: 'Front Knee Position',
          tipWhenViolated:
              'Don\'t let your front knee go too far past your toes',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftKnee,
          jointB: PoseLandmarkType.leftAnkle,
          weight: 0.4,
        ),
        FormRule(
          id: 'lunge_torso',
          name: 'Torso Upright',
          tipWhenViolated: 'Keep your torso upright — don\'t lean forward',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.3,
        ),
      ],
      tips: [
        'Step far enough forward so front shin stays vertical',
        'Lower until both knees are at ~90°',
        'Push through the front heel to return to standing',
      ],
      commonMistakes: [
        'Taking too short a step — puts stress on the knee',
        'Leaning forward — keep your torso upright',
        'Front knee caving inward',
      ],
      difficultyScore: 2.5,
    ),

    ExerciseDefinition(
      key: 'deadlift',
      displayName: 'Deadlift',
      category: 'Back',
      iconEmoji: '🏋️',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftShoulder,
        midJoint: PoseLandmarkType.leftHip,
        endJoint: PoseLandmarkType.leftKnee,
        topAngle: 170, // Standing upright
        bottomAngle: 75, // Hinged forward
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        // Knee angle (should have slight bend, not fully locked)
        AngleConfig(
          startJoint: PoseLandmarkType.leftHip,
          midJoint: PoseLandmarkType.leftKnee,
          endJoint: PoseLandmarkType.leftAnkle,
          topAngle: 175,
          bottomAngle: 140,
          direction: AngleDirection.closing,
        ),
      ],
      formRules: [
        FormRule(
          id: 'deadlift_neutral_spine',
          name: 'Neutral Spine',
          tipWhenViolated: 'Keep your back flat — don\'t round your lower back',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.5,
        ),
        FormRule(
          id: 'deadlift_knee_bend',
          name: 'Knee Position',
          tipWhenViolated:
              'Maintain a slight knee bend — don\'t lock your knees',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftHip,
          jointB: PoseLandmarkType.leftKnee,
          jointC: PoseLandmarkType.leftAnkle,
          idealMin: 140,
          idealMax: 175,
          weight: 0.3,
        ),
      ],
      tips: [
        'Hinge at the hips, don\'t just bend over',
        'Keep the bar close to your body throughout',
        'Engage your lats to keep the bar on path',
      ],
      commonMistakes: [
        'Rounding the lower back — keep it flat and neutral',
        'Locking out the knees at the bottom',
        'Jerking the weight off the floor',
      ],
      difficultyScore: 3.5,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // CORE EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'sit_up',
      displayName: 'Sit-Up',
      category: 'Core',
      iconEmoji: '🧱',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftKnee,
        midJoint: PoseLandmarkType.leftHip,
        endJoint: PoseLandmarkType.leftShoulder,
        topAngle: 80, // Lying down (hip angle open)
        bottomAngle: 35, // Sitting up (hip angle closed)
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [],
      formRules: [
        FormRule(
          id: 'situp_knee_angle',
          name: 'Knee Bend',
          tipWhenViolated: 'Bend your knees to ~90° — feet flat on the floor',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftHip,
          jointB: PoseLandmarkType.leftKnee,
          jointC: PoseLandmarkType.leftAnkle,
          idealMin: 70,
          idealMax: 110,
          weight: 0.4,
        ),
      ],
      tips: [
        'Roll up slowly, don\'t jerk',
        'Exhale on the way up, inhale on the way down',
        'Keep your feet flat on the floor',
      ],
      commonMistakes: [
        'Pulling on your neck — hands behind ears only',
        'Using momentum instead of core strength',
        'Not going all the way up',
      ],
      difficultyScore: 1.5,
    ),

    ExerciseDefinition(
      key: 'plank',
      displayName: 'Plank',
      category: 'Core',
      iconEmoji: '🧘',
      type: ExerciseType.hold,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftShoulder,
        midJoint: PoseLandmarkType.leftHip,
        endJoint: PoseLandmarkType.leftKnee,
        topAngle: 170,
        bottomAngle: 170, // Plank is about holding, not moving
        direction: AngleDirection.opening,
      ),
      secondaryAngles: [
        // Elbow angle (should be ~90° in forearm plank)
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftElbow,
          endJoint: PoseLandmarkType.leftWrist,
          topAngle: 90,
          bottomAngle: 90,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'plank_body_line',
          name: 'Body Alignment',
          tipWhenViolated:
              'Keep your body in a straight line — no sagging or piking',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          jointC: PoseLandmarkType.leftKnee,
          idealMin: 155,
          idealMax: 190,
          weight: 0.6,
        ),
        FormRule(
          id: 'plank_hip_sag',
          name: 'Hip Position',
          tipWhenViolated:
              'Don\'t let your hips sag — squeeze your glutes and core',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.4,
        ),
      ],
      tips: [
        'Engage your core by pulling your belly button in',
        'Squeeze your glutes to maintain a straight line',
        'Look at a spot between your hands',
      ],
      commonMistakes: [
        'Hips sagging toward the floor',
        'Piking hips too high',
        'Holding breath — breathe steadily',
      ],
      difficultyScore: 2.0,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // FULL BODY / CARDIO
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'jumping_jack',
      displayName: 'Jumping Jack',
      category: 'Cardio',
      iconEmoji: '⚡',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftShoulder,
        endJoint: PoseLandmarkType.leftElbow,
        topAngle: 165, // Arms down
        bottomAngle: 90, // Arms up
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        AngleConfig(
          startJoint: PoseLandmarkType.leftHip,
          midJoint: PoseLandmarkType.leftKnee,
          endJoint: PoseLandmarkType.leftAnkle,
          topAngle: 170,
          bottomAngle: 170,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'jack_arm_symmetry',
          name: 'Arm Symmetry',
          tipWhenViolated: 'Raise both arms evenly overhead',
          type: RuleType.symmetry,
          jointA: PoseLandmarkType.leftElbow,
          jointB: PoseLandmarkType.rightElbow,
          weight: 0.5,
        ),
      ],
      tips: [
        'Fully extend arms overhead on each rep',
        'Land softly on the balls of your feet',
        'Keep a steady rhythm',
      ],
      commonMistakes: [
        'Not extending arms fully overhead',
        'Landing with stiff knees',
        'Losing rhythm and coordination',
      ],
      difficultyScore: 1.0,
    ),

    ExerciseDefinition(
      key: 'mountain_climber',
      displayName: 'Mountain Climber',
      category: 'Cardio',
      iconEmoji: '🏔️',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftKnee,
        endJoint: PoseLandmarkType.leftAnkle,
        topAngle: 160, // Leg extended back
        bottomAngle: 70, // Knee driven forward
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [
        // Body should stay in plank position
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftHip,
          endJoint: PoseLandmarkType.leftKnee,
          topAngle: 170,
          bottomAngle: 170,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'climber_body_line',
          name: 'Plank Position',
          tipWhenViolated:
              'Keep your hips level — don\'t bounce them up and down',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftHip,
          weight: 0.5,
        ),
      ],
      tips: [
        'Drive knees toward chest with control',
        'Keep hips down and level',
        'Maintain a steady pace',
      ],
      commonMistakes: [
        'Bouncing hips up and down',
        'Not driving knees high enough',
        'Sagging lower back',
      ],
      difficultyScore: 2.5,
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // ACCESSORY EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    ExerciseDefinition(
      key: 'tricep_extension',
      displayName: 'Tricep Extension',
      category: 'Arms',
      iconEmoji: '🦾',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftShoulder,
        midJoint: PoseLandmarkType.leftElbow,
        endJoint: PoseLandmarkType.leftWrist,
        topAngle: 160, // Arm extended
        bottomAngle: 55, // Forearm curled behind head
        direction: AngleDirection.closing,
      ),
      secondaryAngles: [],
      formRules: [
        FormRule(
          id: 'tricep_elbow_position',
          name: 'Elbow Position',
          tipWhenViolated:
              'Keep your elbows pointing forward — don\'t let them flare out',
          type: RuleType.alignment,
          jointA: PoseLandmarkType.leftShoulder,
          jointB: PoseLandmarkType.leftElbow,
          weight: 0.5,
        ),
      ],
      tips: [
        'Keep your upper arm vertical and still',
        'Only move your forearm — isolate the tricep',
        'Squeeze at full extension',
      ],
      commonMistakes: [
        'Moving the elbow — upper arm should stay still',
        'Flaring elbows outward',
        'Using too much weight and losing form',
      ],
      difficultyScore: 2.0,
    ),

    ExerciseDefinition(
      key: 'lateral_raise',
      displayName: 'Lateral Raise',
      category: 'Shoulders',
      iconEmoji: '🦅',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftHip,
        midJoint: PoseLandmarkType.leftShoulder,
        endJoint: PoseLandmarkType.leftElbow,
        topAngle: 85, // Arms raised to shoulder height
        bottomAngle: 15, // Arms at sides
        direction: AngleDirection.opening,
      ),
      secondaryAngles: [
        // Elbow should be slightly bent (~170°) throughout
        AngleConfig(
          startJoint: PoseLandmarkType.leftShoulder,
          midJoint: PoseLandmarkType.leftElbow,
          endJoint: PoseLandmarkType.leftWrist,
          topAngle: 170,
          bottomAngle: 170,
          direction: AngleDirection.opening,
        ),
      ],
      formRules: [
        FormRule(
          id: 'lateral_raise_height',
          name: 'Raise Height',
          tipWhenViolated: 'Raise arms to shoulder height — no higher',
          type: RuleType.angle,
          jointA: PoseLandmarkType.leftHip,
          jointB: PoseLandmarkType.leftShoulder,
          jointC: PoseLandmarkType.leftElbow,
          idealMin: 70,
          idealMax: 100,
          weight: 0.4,
          activePhases: {'top'},
        ),
        FormRule(
          id: 'lateral_raise_symmetry',
          name: 'Arm Symmetry',
          tipWhenViolated: 'Raise both arms at the same speed and height',
          type: RuleType.symmetry,
          jointA: PoseLandmarkType.leftElbow,
          jointB: PoseLandmarkType.rightElbow,
          weight: 0.4,
        ),
      ],
      tips: [
        'Lead with your elbows, not your hands',
        'Slight bend in the elbows throughout',
        'Pour from a pitcher at the top (slight external rotation)',
      ],
      commonMistakes: [
        'Raising above shoulder height — risks impingement',
        'Using momentum by swinging the body',
        'Shrugging shoulders up — keep them down and back',
      ],
      difficultyScore: 2.0,
    ),

    ExerciseDefinition(
      key: 'calf_raise',
      displayName: 'Calf Raise',
      category: 'Legs',
      iconEmoji: '🦶',
      type: ExerciseType.reps,
      primaryAngle: AngleConfig(
        startJoint: PoseLandmarkType.leftKnee,
        midJoint: PoseLandmarkType.leftAnkle,
        endJoint: PoseLandmarkType.leftFootIndex,
        topAngle: 130, // Up on toes
        bottomAngle: 90, // Heels down
        direction: AngleDirection.opening,
      ),
      secondaryAngles: [],
      formRules: [
        FormRule(
          id: 'calf_raise_symmetry',
          name: 'Leg Symmetry',
          tipWhenViolated: 'Rise evenly on both feet',
          type: RuleType.symmetry,
          jointA: PoseLandmarkType.leftAnkle,
          jointB: PoseLandmarkType.rightAnkle,
          weight: 0.4,
        ),
      ],
      tips: [
        'Rise all the way up onto the balls of your feet',
        'Squeeze your calves at the top for a full second',
        'Lower slowly past the flat-foot position for a stretch',
      ],
      commonMistakes: [
        'Partial range of motion — go all the way up and down',
        'Bouncing at the bottom — use control',
        'Bending the knees — keep legs straight',
      ],
      difficultyScore: 1.0,
    ),
  ];

  /// Lookup by key
  static ExerciseDefinition? findByKey(String key) {
    try {
      return all.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Get exercises by category
  static List<ExerciseDefinition> getByCategory(String category) {
    return all.where((e) => e.category == category).toList();
  }

  /// All unique categories
  static List<String> get categories =>
      all.map((e) => e.category).toSet().toList()..sort();
}
