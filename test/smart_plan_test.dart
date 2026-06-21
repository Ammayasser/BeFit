import 'package:flutter_test/flutter_test.dart';
import 'package:befit/features/smart_plan/data/models/smart_meal_plan.dart';
import 'package:befit/features/smart_plan/data/models/smart_workout_plan.dart';

void main() {
  group('SmartMealPlan Model Tests', () {
    test('SmartMealRecipe.fromJson parses correctly', () {
      final json = {
        'food': 'Oatmeal',
        'calories': 350.5,
        'protein': 12,
        'carbohydrates': '54.5', // test string conversion
        'fat': null, // test null safety
      };

      final recipe = SmartMealRecipe.fromJson(json);

      expect(recipe.food, 'Oatmeal');
      expect(recipe.calories, 350.5);
      expect(recipe.protein, 12.0);
      expect(recipe.carbohydrates, 54.5);
      expect(recipe.fat, 0.0);
    });

    test('SmartMealRecipe.toJson serializes correctly', () {
      const recipe = SmartMealRecipe(
        food: 'Eggs',
        calories: 140.0,
        protein: 12.0,
        carbohydrates: 1.0,
        fat: 10.0,
      );

      final json = recipe.toJson();

      expect(json['food'], 'Eggs');
      expect(json['calories'], 140.0);
      expect(json['protein'], 12.0);
      expect(json['carbohydrates'], 1.0);
      expect(json['fat'], 10.0);
    });

    test('SmartMealPlan.fromApiResponse parses correctly', () {
      final apiResponse = {
        'recommended_calories': 2000.0,
        'bmi': 22.5,
        'bmi_category': 'Normal',
        'bmr': 1500.0,
        'tdee': 2200.0,
        'goal': 'Gain Weight',
        'meals': {
          'breakfast': {
            'recipes': [
              {
                'food': 'Protein Shake',
                'calories': 300,
                'protein': 30,
                'carbohydrates': 10,
                'fat': 3
              }
            ]
          },
          'lunch': {
            'recipes': [
              {
                'food': 'Chicken Rice',
                'calories': 600,
                'protein': 45,
                'carbohydrates': 50,
                'fat': 12
              }
            ]
          },
          'dinner': {
            'recipes': []
          }
        }
      };

      final plan = SmartMealPlan.fromApiResponse(apiResponse);

      expect(plan.recommendedCalories, 2000.0);
      expect(plan.bmi, 22.5);
      expect(plan.bmiCategory, 'Normal');
      expect(plan.bmr, 1500.0);
      expect(plan.tdee, 2200.0);
      expect(plan.goal, 'Gain Weight');
      expect(plan.breakfast.length, 1);
      expect(plan.breakfast.first.food, 'Protein Shake');
      expect(plan.lunch.length, 1);
      expect(plan.lunch.first.food, 'Chicken Rice');
      expect(plan.dinner, isEmpty);
    });

    test('SmartMealPlan toJson and fromJson roundtrip correctly', () {
      const recipe = SmartMealRecipe(
        food: 'Greek Yogurt',
        calories: 150.0,
        protein: 15.0,
        carbohydrates: 6.0,
        fat: 2.0,
      );

      final plan = SmartMealPlan(
        recommendedCalories: 1800.0,
        bmi: 24.0,
        bmiCategory: 'Normal',
        bmr: 1400.0,
        tdee: 2000.0,
        goal: 'Lose Weight',
        breakfast: [recipe],
        lunch: [],
        dinner: [],
        generatedAt: DateTime.parse('2026-05-30T00:00:00.000Z'),
      );

      final json = plan.toJson();
      final parsedPlan = SmartMealPlan.fromJson(json);

      expect(parsedPlan.recommendedCalories, 1800.0);
      expect(parsedPlan.bmi, 24.0);
      expect(parsedPlan.bmiCategory, 'Normal');
      expect(parsedPlan.breakfast.length, 1);
      expect(parsedPlan.breakfast.first.food, 'Greek Yogurt');
      expect(parsedPlan.generatedAt, plan.generatedAt);
    });
  });

  group('SmartWorkoutPlan Model Tests', () {
    test('SmartWorkoutExercise fromJson and toJson', () {
      final json = {
        'name': 'Bench Press',
        'sets': 4,
        'reps': '8-10',
        'notes': 'Keep form tight',
        'muscleGroup': 'Chest',
        'gifUrl': 'https://example.com/bench.gif',
      };

      final exercise = SmartWorkoutExercise.fromJson(json);

      expect(exercise.name, 'Bench Press');
      expect(exercise.sets, 4);
      expect(exercise.reps, '8-10');
      expect(exercise.notes, 'Keep form tight');
      expect(exercise.muscleGroup, 'Chest');
      expect(exercise.gifUrl, 'https://example.com/bench.gif');

      final serialized = exercise.toJson();
      expect(serialized['name'], 'Bench Press');
      expect(serialized['sets'], 4);
      expect(serialized['reps'], '8-10');
      expect(serialized['notes'], 'Keep form tight');
      expect(serialized['muscleGroup'], 'Chest');
      expect(serialized['gifUrl'], 'https://example.com/bench.gif');
    });

    test('SmartWorkoutDay dayAbbr getter helper', () {
      const workoutDay1 = SmartWorkoutDay(
        dayIndex: 1,
        name: 'Push Day',
        isRestDay: false,
        exercises: [],
      );
      const workoutDay7 = SmartWorkoutDay(
        dayIndex: 7,
        name: 'Active Recovery',
        isRestDay: true,
        exercises: [],
      );

      expect(workoutDay1.dayAbbr, 'Mon');
      expect(workoutDay7.dayAbbr, 'Sun');
    });

    test('SmartWorkoutDay primaryMuscles extraction', () {
      const exercises = [
        SmartWorkoutExercise(name: 'Push Ups', sets: 3, reps: '12', muscleGroup: 'Chest'),
        SmartWorkoutExercise(name: 'Shoulder Press', sets: 3, reps: '10', muscleGroup: 'Shoulders'),
        SmartWorkoutExercise(name: 'Tricep Dips', sets: 3, reps: '15', muscleGroup: 'Triceps'),
        SmartWorkoutExercise(name: 'Incline Bench', sets: 3, reps: '8', muscleGroup: 'Chest'), // Duplicate
      ];

      const day = SmartWorkoutDay(
        dayIndex: 2,
        name: 'Push Routine',
        isRestDay: false,
        exercises: exercises,
      );

      expect(day.primaryMuscles, containsAll(['Chest', 'Shoulders', 'Triceps']));
      expect(day.primaryMuscles.length, 3); // Max 3 unique muscles
    });

    test('SmartWorkoutDay fromJson and toJson', () {
      final json = {
        'dayIndex': 3,
        'name': 'Leg Day',
        'isRestDay': false,
        'exercises': [
          {
            'name': 'Squats',
            'sets': 4,
            'reps': '10',
            'muscleGroup': 'Quads',
          }
        ]
      };

      final day = SmartWorkoutDay.fromJson(json);

      expect(day.dayIndex, 3);
      expect(day.name, 'Leg Day');
      expect(day.isRestDay, false);
      expect(day.exercises.length, 1);
      expect(day.exercises.first.name, 'Squats');

      final serialized = day.toJson();
      expect(serialized['dayIndex'], 3);
      expect(serialized['name'], 'Leg Day');
      expect(serialized['isRestDay'], false);
      expect((serialized['exercises'] as List).first['name'], 'Squats');
    });
  });
}
