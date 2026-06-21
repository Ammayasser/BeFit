class MuscleNameResolver {
  static List<int> resolveToIds(String muscleName) {
    final clean = muscleName.trim().toLowerCase();
    final ids = <int>[];
    
    if (clean.contains('chest') || clean.contains('pectoral')) ids.add(4);
    if (clean.contains('abs') || clean.contains('abdominals') || clean.contains('core')) {
      ids.addAll([6, 14]); 
    }
    if (clean.contains('biceps')) ids.addAll([1, 13]); 
    if (clean.contains('triceps')) ids.add(5);
    if (clean.contains('shoulders') || clean.contains('deltoid')) ids.add(2);
    if (clean.contains('quadriceps') || clean.contains('quads')) ids.add(10);
    if (clean.contains('hamstrings')) ids.add(11);
    if (clean.contains('glutes')) ids.add(8);
    if (clean.contains('calves') || clean.contains('calf')) ids.addAll([7, 15]); 
    if (clean.contains('trapezius') || clean.contains('traps')) ids.add(9);
    if (clean.contains('back') || clean.contains('lats')) ids.add(12);
    if (clean.contains('lower-back')) ids.add(16);
    
    return ids;
  }

  static bool isBackMuscle(int id) {
    return const [5, 7, 8, 9, 11, 12, 15, 16].contains(id);
  }
}
