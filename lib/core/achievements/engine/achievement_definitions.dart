// lib/core/achievements/engine/achievement_definitions.dart

import '../models/achievement_models.dart';
import '../models/achievement_event.dart';

class AchievementDefinitions {
  static const List<Achievement> all = [
    // --- FITNESS: VOLUME & INTENSITY ---
    Achievement(
      id: 'first_workout',
      title: 'First Step',
      description: 'Complete your first workout session to begin your journey.',
      icon: 'fitness_center',
      category: AchievementCategory.fitness,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.workoutCompleted, type: RequirementType.count, targetValue: 1),
      ],
      points: 5,
    ),
    Achievement(
      id: 'iron_disciple',
      title: 'Iron Disciple',
      description: 'Log a total volume of 5,000kg across all your weightlifting sessions.',
      icon: 'fitness_center',
      category: AchievementCategory.fitness,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.workoutCompleted, type: RequirementType.sum, targetValue: 5000, dataKey: 'volume'),
      ],
      points: 50,
    ),
    Achievement(
      id: 'volume_titan',
      title: 'Volume Titan',
      description: 'Log a total volume of 50,000kg. Your strength is becoming legendary.',
      icon: 'fitness_center',
      category: AchievementCategory.fitness,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.workoutCompleted, type: RequirementType.sum, targetValue: 50000, dataKey: 'volume'),
      ],
      points: 250,
    ),
    Achievement(
      id: 'reps_reaper',
      title: 'The Finisher',
      description: 'Complete a total of 1,000 repetitions across all exercises.',
      icon: 'bolt',
      category: AchievementCategory.fitness,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.workoutCompleted, type: RequirementType.sum, targetValue: 1000, dataKey: 'reps'),
      ],
      points: 75,
    ),

    // --- NUTRITION: PRECISION & FUEL ---
    Achievement(
      id: 'clean_eater_lite',
      title: 'Clean Eater',
      description: 'Log 5 healthy meals to establish a nutritional baseline.',
      icon: 'restaurant',
      category: AchievementCategory.nutrition,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.mealLogged, type: RequirementType.count, targetValue: 5),
      ],
      points: 20,
    ),
    Achievement(
      id: 'nutrition_master',
      title: 'Nutrition Architect',
      description: 'Log 50 meals. You are building your body with precision.',
      icon: 'restaurant',
      category: AchievementCategory.nutrition,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.mealLogged, type: RequirementType.count, targetValue: 50),
      ],
      points: 150,
    ),
    Achievement(
      id: 'hydration_hero',
      title: 'Hydration Hero',
      description: 'Reach 2,000ml of water in a single day. Stay fluid, stay fast.',
      icon: 'water_drop',
      category: AchievementCategory.nutrition,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.waterLogged, type: RequirementType.minValue, targetValue: 2000, dataKey: 'daily_total'),
      ],
      points: 25,
    ),
    Achievement(
      id: 'aqua_king',
      title: 'Aqua King',
      description: 'Drink 4,000ml of water in a single day. Elite hydration status.',
      icon: 'water_drop',
      category: AchievementCategory.nutrition,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.waterLogged, type: RequirementType.minValue, targetValue: 4000, dataKey: 'daily_total'),
      ],
      points: 60,
    ),

    // --- CONSISTENCY: THE GRIND ---
    Achievement(
      id: 'week_warrior',
      title: '7-Day Grind',
      description: 'Maintain a 7-day activity streak without skipping a beat.',
      icon: 'local_fire_department',
      category: AchievementCategory.consistency,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.streakUpdated, type: RequirementType.streak, targetValue: 7, dataKey: 'streak_count'),
      ],
      points: 100,
    ),
    Achievement(
      id: 'month_monarch',
      title: 'Monthly Momentum',
      description: 'Reach a 30-day streak. You are now truly unstoppable.',
      icon: 'local_fire_department',
      category: AchievementCategory.consistency,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.streakUpdated, type: RequirementType.streak, targetValue: 30, dataKey: 'streak_count'),
      ],
      points: 500,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Morning Glory',
      description: 'Complete 5 workouts before 8:00 AM.',
      icon: 'bolt',
      category: AchievementCategory.consistency,
      requirements: [
        AchievementRequirement(
          id: 'req_1', 
          eventType: AchievementEventType.workoutCompleted, 
          type: RequirementType.count, 
          targetValue: 5,
          dataFilter: {'start_hour': '<8'},
        ),
      ],
      points: 40,
    ),

    // --- MILESTONES: PHYSICAL CHANGES ---
    Achievement(
      id: 'weight_pioneer',
      title: 'Body Pioneer',
      description: 'Log your body weight for 7 consecutive days.',
      icon: 'landscape',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.weightLogged, type: RequirementType.count, targetValue: 7),
      ],
      points: 30,
    ),
    Achievement(
      id: 'goal_getter',
      title: 'Milestone Crusher',
      description: 'Reach your first weight or fat-loss milestone goal.',
      icon: 'award',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(id: 'req_1', eventType: AchievementEventType.achievementUnlocked, type: RequirementType.count, targetValue: 1),
      ],
      points: 100,
    ),
    Achievement(
      id: 'first_weight_logged',
      title: 'First Weigh-In',
      description: 'Log your body weight for the first time to start tracking progress.',
      icon: 'award',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.count,
          targetValue: 1,
          dataFilter: {'is_first': true},
        ),
      ],
      points: 10,
    ),
    Achievement(
      id: 'weight_goal_reached',
      title: 'Goal Achieved!',
      description: 'Successfully reach your target weight goal.',
      icon: 'award',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.count,
          targetValue: 1,
          dataFilter: {'goal_reached': true},
        ),
      ],
      points: 150,
    ),
    Achievement(
      id: 'five_kg_lost',
      title: 'Shifting Scales (5kg)',
      description: 'Achieve a weight loss milestone of 5kg.',
      icon: 'bolt',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.minValue,
          targetValue: 5.0,
          dataKey: 'kg_lost',
        ),
      ],
      points: 50,
    ),
    Achievement(
      id: 'ten_pounds_lost',
      title: 'Pounds Away (10lbs)',
      description: 'Achieve a weight loss milestone of 10lbs.',
      icon: 'bolt',
      category: AchievementCategory.milestone,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.minValue,
          targetValue: 4.53592, // 10 lbs in kg
          dataKey: 'kg_lost',
        ),
      ],
      points: 50,
    ),
    Achievement(
      id: 'weight_streak_7',
      title: 'Weekly Consistency',
      description: 'Log your weight 7 days in a row.',
      icon: 'local_fire_department',
      category: AchievementCategory.consistency,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.minValue,
          targetValue: 7.0,
          dataKey: 'streak_count',
        ),
      ],
      points: 30,
    ),
    Achievement(
      id: 'weight_streak_30',
      title: 'Monthly Scale Grit',
      description: 'Log your weight 30 days in a row.',
      icon: 'local_fire_department',
      category: AchievementCategory.consistency,
      requirements: [
        AchievementRequirement(
          id: 'req_1',
          eventType: AchievementEventType.weightLogged,
          type: RequirementType.minValue,
          targetValue: 30.0,
          dataKey: 'streak_count',
        ),
      ],
      points: 100,
    ),
  ];
}

