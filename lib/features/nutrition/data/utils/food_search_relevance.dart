import 'dart:math' show min;

/// Shared name-based relevance for merging USDA + Open Food Facts results
/// and for optional UI grouping (e.g. "Best match").
///
/// [secondaryLabel] is optional metadata (e.g. USDA `foodCategory` stored in
/// [FoodItem.brand]) used to avoid misleading top hits.
int foodNameRelevanceScore(
  String itemName,
  String query, {
  String? secondaryLabel,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;

  final name = itemName.toLowerCase();
  final head = name.split(',').first.trim();

  // "meat" should not match "meatless"
  if (q == 'meat' && RegExp(r'\bmeatless\b').hasMatch(name)) return 5;

  int score;
  if (name == q) {
    score = 100;
  } else if (head == q) {
    score = 98;
  } else if (name.startsWith(q)) {
    score = 90;
  } else if (RegExp('^${RegExp.escape(q)}[,\\s]').hasMatch(name)) {
    score = 88;
  } else if (RegExp('\\b${RegExp.escape(q)}\\b').hasMatch(head)) {
    score = 85;
  } else if (RegExp('\\b${RegExp.escape(q)}\\b').hasMatch(name)) {
    score = 38;
  } else if (name.contains(q)) {
    score = head.contains(q) ? 70 : 32;
  } else {
    score = 10;
  }

  score = _applyGroceryNoisePenalty(name, q, score);
  return _applyCategoryHintPenalty(q, secondaryLabel, score);
}

/// Down-rank items that match the query textually but are usually not what
/// people mean (e.g. "Meat extender" for query "meat").
int _applyGroceryNoisePenalty(String nameLower, String query, int score) {
  if (score <= 10) return score;

  const fragments = [
    'extender',
    'substitute',
    'imitation',
    'analog',
    'textured vegetable protein',
    'tvp',
    'meat analog',
    'plant-based',
    'vegetarian',
    'vegan',
  ];

  for (final frag in fragments) {
    if (nameLower.contains(frag)) {
      return min(score, 44);
    }
  }

  // Soy / legume “meat” products when searching generic “meat”
  if (query == 'meat') {
    const legumeHints = [
      'legume',
      'soy',
      'tofu',
      'tempeh',
      'seitan',
      'textured',
    ];
    for (final h in legumeHints) {
      if (nameLower.contains(h)) return min(score, 48);
    }
  }

  return score;
}

int _applyCategoryHintPenalty(String query, String? secondaryLabel, int score) {
  if (score <= 10 || secondaryLabel == null) return score;
  final hint = secondaryLabel.toLowerCase();

  if (query == 'meat') {
    if (hint.contains('legume') ||
        hint.contains('confection') ||
        hint.contains('sweets')) {
      return min(score, 36);
    }
  }
  return score;
}
