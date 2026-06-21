class FoodItemEntity {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final String? imageUrl;

  const FoodItemEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    this.imageUrl,
  });
}
