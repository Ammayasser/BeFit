class CalorieHistoryItem {
  final DateTime date;
  final double caloriesEaten;
  final int calorieGoal;

  CalorieHistoryItem({
    required this.date,
    required this.caloriesEaten,
    required this.calorieGoal,
  });

  bool get isGoalMet => caloriesEaten > 0 && caloriesEaten <= (calorieGoal * 1.05);
  double get goalCompletionRatio => calorieGoal > 0 ? (caloriesEaten / calorieGoal).clamp(0.0, 1.2) : 0.0;
}
