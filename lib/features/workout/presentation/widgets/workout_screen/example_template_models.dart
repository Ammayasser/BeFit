class ExampleTemplate {
  final String name;
  final List<ExampleExercise> exercises;

  const ExampleTemplate({
    required this.name,
    required this.exercises,
  });
}

class ExampleExercise {
  final String name;
  final String muscleGroup;
  final int sets;

  const ExampleExercise({
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });
}
