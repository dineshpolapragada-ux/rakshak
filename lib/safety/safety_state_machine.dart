import 'package:flutter/foundation.dart';

import 'safety_state.dart';

class RakshakSafetyStateMachine {
  RakshakSafetyState _state = RakshakSafetyState.safe;

  RakshakSafetyState get state => _state;

  bool transitionTo(RakshakSafetyState nextState) {
    if (!_isValidTransition(_state, nextState)) {
      debugPrint(
        '⚠️ RAKSHAK STATE MACHINE: '
        'Invalid transition $_state → $nextState',
      );

      return false;
    }

    debugPrint(
      '🔄 RAKSHAK STATE MACHINE: '
      '$_state → $nextState',
    );

    _state = nextState;

    return true;
  }

  bool _isValidTransition(RakshakSafetyState current, RakshakSafetyState next) {
    switch (current) {
      case RakshakSafetyState.safe:
        return next == RakshakSafetyState.triggered;

      case RakshakSafetyState.triggered:
        return next == RakshakSafetyState.evaluating ||
            next == RakshakSafetyState.resolved;

      case RakshakSafetyState.evaluating:
        return next == RakshakSafetyState.alerting ||
            next == RakshakSafetyState.resolved;

      case RakshakSafetyState.alerting:
        return next == RakshakSafetyState.resolved;

      case RakshakSafetyState.resolved:
        return next == RakshakSafetyState.safe;
    }
  }

  void reset() {
    debugPrint('♻️ RAKSHAK STATE MACHINE: Resetting to SAFE');

    _state = RakshakSafetyState.safe;
  }
}
