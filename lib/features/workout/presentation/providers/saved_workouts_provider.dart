import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedWorkoutsProvider extends ChangeNotifier {
  static const _prefsKey = 'befit_saved_workout_ids_v1';

  final Set<String> _savedIds = {};
  bool _loaded = false;

  Set<String> get savedIds => Set.unmodifiable(_savedIds);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _savedIds
      ..clear()
      ..addAll(raw);
    _loaded = true;
    notifyListeners();
  }

  bool isSaved(String routeId) => _savedIds.contains(routeId);

  Future<void> toggle(String routeId) async {
    if (_savedIds.contains(routeId)) {
      _savedIds.remove(routeId);
    } else {
      _savedIds.add(routeId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _savedIds.toList());
  }
}
