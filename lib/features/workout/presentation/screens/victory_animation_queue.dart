import 'dart:async';
import 'package:flutter/material.dart';

enum VictoryPhase {
  impact,
  muscleGlow,
  prExplosion,
  scoreCard,
  completed
}

class VictoryAnimationQueue extends ChangeNotifier {
  VictoryPhase _currentPhase = VictoryPhase.impact;
  VictoryPhase get currentPhase => _currentPhase;

  bool _isSkipping = false;
  bool get isSkipping => _isSkipping;

  final Map<VictoryPhase, Completer<void>> _phaseCompleters = {
    VictoryPhase.impact: Completer<void>(),
    VictoryPhase.muscleGlow: Completer<void>(),
    VictoryPhase.prExplosion: Completer<void>(),
    VictoryPhase.scoreCard: Completer<void>(),
  };

  void advancePhase() {
    if (_currentPhase == VictoryPhase.completed) return;
    
    _phaseCompleters[_currentPhase]?.complete();
    
    final nextIndex = VictoryPhase.values.indexOf(_currentPhase) + 1;
    if (nextIndex < VictoryPhase.values.length) {
      _currentPhase = VictoryPhase.values[nextIndex];
      notifyListeners();
    }
  }

  void skip() {
    if (_currentPhase == VictoryPhase.scoreCard || _currentPhase == VictoryPhase.completed) return;
    _isSkipping = true;
    notifyListeners();
    
    // Rapidly advance phases
    _currentPhase = VictoryPhase.scoreCard;
    _isSkipping = false;
    notifyListeners();
  }

  Future<void> waitForPhase(VictoryPhase phase) => _phaseCompleters[phase]!.future;
}
