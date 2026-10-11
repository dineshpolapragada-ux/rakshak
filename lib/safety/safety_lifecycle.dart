import 'package:flutter/foundation.dart';

import 'safety_state.dart';
import 'safety_state_machine.dart';

class RakshakSafetyLifecycle {
  final RakshakSafetyStateMachine stateMachine;

  RakshakSafetyLifecycle({required this.stateMachine});

  bool evaluate() {
    debugPrint('🔎 RAKSHAK LIFECYCLE: Starting safety evaluation');

    if (stateMachine.state != RakshakSafetyState.triggered) {
      debugPrint(
        '⚠️ RAKSHAK LIFECYCLE: '
        'Cannot evaluate from ${stateMachine.state}',
      );
      return false;
    }

    final success = stateMachine.transitionTo(RakshakSafetyState.evaluating);

    if (success) {
      debugPrint(
        '🔎 RAKSHAK LIFECYCLE: '
        'State = ${stateMachine.state}',
      );
    }

    return success;
  }

  bool beginAlerting() {
    debugPrint('🚨 RAKSHAK LIFECYCLE: Starting alert phase');

    if (stateMachine.state != RakshakSafetyState.evaluating) {
      debugPrint(
        '⚠️ RAKSHAK LIFECYCLE: '
        'Cannot alert from ${stateMachine.state}',
      );
      return false;
    }

    final success = stateMachine.transitionTo(RakshakSafetyState.alerting);

    if (success) {
      debugPrint(
        '🚨 RAKSHAK LIFECYCLE: '
        'State = ${stateMachine.state}',
      );
    }

    return success;
  }

  bool resolve() {
    debugPrint('✅ RAKSHAK LIFECYCLE: Resolving safety incident');

    if (stateMachine.state != RakshakSafetyState.alerting) {
      debugPrint(
        '⚠️ RAKSHAK LIFECYCLE: '
        'Cannot resolve from ${stateMachine.state}',
      );
      return false;
    }

    final success = stateMachine.transitionTo(RakshakSafetyState.resolved);

    if (success) {
      debugPrint(
        '✅ RAKSHAK LIFECYCLE: '
        'State = ${stateMachine.state}',
      );
    }

    return success;
  }

  bool returnToSafe() {
    debugPrint('♻️ RAKSHAK LIFECYCLE: Returning to SAFE');

    if (stateMachine.state != RakshakSafetyState.resolved) {
      debugPrint(
        '⚠️ RAKSHAK LIFECYCLE: '
        'Cannot return to SAFE from ${stateMachine.state}',
      );
      return false;
    }

    final success = stateMachine.transitionTo(RakshakSafetyState.safe);

    if (success) {
      debugPrint(
        '♻️ RAKSHAK LIFECYCLE: '
        'State = ${stateMachine.state}',
      );
    }

    return success;
  }
}
