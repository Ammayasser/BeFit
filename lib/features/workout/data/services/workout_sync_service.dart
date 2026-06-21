import 'dart:async';
import 'package:flutter/foundation.dart';
import 'fitbod_data_loader.dart';

class WorkoutSyncService {
  final FitbodDataLoader _dataLoader;

  WorkoutSyncService({
    FitbodDataLoader? dataLoader,
  }) : _dataLoader = dataLoader ?? FitbodDataLoader();

  Future<bool> isSynced() async {
    return await _dataLoader.isLoaded();
  }

  Future<void> markSynced(bool value) async {
    if (!value) {
      await _dataLoader.invalidate();
    }
  }

  Future<bool> performSync(void Function(double progress) onProgress) async {
    debugPrint('[WorkoutSyncService] Delegating sync to FitbodDataLoader...');
    return await _dataLoader.loadFromAssets(onProgress);
  }
}
