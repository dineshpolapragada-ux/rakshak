import 'package:flutter/foundation.dart';

import 'alert_orchestrator.dart';
import 'location_snapshot.dart';
import 'trigger_classifier.dart';
import 'safety_session.dart';

import '../background/rakshak_safety_event.dart';
import 'safety_lifecycle.dart';
import 'safety_evaluator.dart';
import 'safety_context_builder.dart';
import 'safety_evaluation_result.dart';
import 'safety_policy.dart';
import 'safety_state.dart';
import 'trusted_contact_action.dart';
import 'alert_dispatcher.dart';
import 'test_alert_dispatcher.dart';
import 'safety_state_machine.dart';
import '../models/rakshak_incident.dart';
import 'production_alert_dispatcher.dart';
import 'alert_recipient.dart';

class RakshakSafetyController {
  final RakshakTestAlertDispatcher testAlertDispatcher = const RakshakTestAlertDispatcher();
  final RakshakSafetyStateMachine stateMachine = RakshakSafetyStateMachine();

  RakshakIncident? _currentIncident;

  final RakshakSafetyPolicy policy = const RakshakSafetyPolicy();

  final RakshakSafetyEvaluator evaluator = const RakshakSafetyEvaluator();

  final RakshakSafetyContextBuilder contextBuilder =
      const RakshakSafetyContextBuilder();

  final RakshakTriggerClassifier triggerClassifier =
      const RakshakTriggerClassifier();

  final RakshakAlertOrchestrator alertOrchestrator =
      const RakshakAlertOrchestrator();
  final RakshakProductionAlertDispatcher productionAlertDispatcher =
    const RakshakProductionAlertDispatcher(
);

  RakshakSafetySession? _currentSession;

  RakshakSafetySession? get currentSession => _currentSession;

  late final RakshakSafetyLifecycle lifecycle = RakshakSafetyLifecycle(
    stateMachine: stateMachine,
  );

  RakshakSafetyState get state => stateMachine.state;

  RakshakIncident? get currentIncident => _currentIncident;

  void handleEvent(RakshakSafetyEvent event) {
    debugPrint('RAKSHAK SAFETY CONTROLLER: Processing ${event.type}');

    final action = policy.evaluate(event);

    debugPrint('RAKSHAK SAFETY POLICY: ${event.type} -> $action');

    switch (action) {
  case RakshakSafetyAction.testTrigger:
    _handleTestTrigger(event);
    break;

  case RakshakSafetyAction.productionTrigger:
    _handleProductionTrigger(event);
    break;

  case RakshakSafetyAction.ignore:
    debugPrint('RAKSHAK SAFETY CONTROLLER: Event ignored by policy');
    break;
}
  }

  void _handleTestTrigger(RakshakSafetyEvent event) {
    debugPrint('RAKSHAK SAFETY CONTROLLER: Test safety trigger approved');

    if (state != RakshakSafetyState.safe) {
      debugPrint(
        'RAKSHAK SAFETY CONTROLLER: Ignoring trigger because current state is $state',
      );
      return;
    }

    final transitioned = stateMachine.transitionTo(
      RakshakSafetyState.triggered,
    );

    if (!transitioned) {
      debugPrint(
        'RAKSHAK SAFETY CONTROLLER: Failed to transition to TRIGGERED',
      );
      return;
    }

    final now = DateTime.now();

    _currentIncident = RakshakIncident(
      id: 'incident_${now.microsecondsSinceEpoch}',
      createdAt: now,
      triggerType: event.type,
      triggerSource: event.source,
      state: RakshakSafetyState.triggered,
      lastUpdatedAt: now,
    );

    final trigger = triggerClassifier.classify(
      type: event.type,
      source: event.source,
    );

    _currentSession = RakshakSafetySession(
      sessionId: _currentIncident!.id,
      startedAt: now,
      triggerType: trigger.name,
      triggerSource: event.source,
      state: RakshakSafetyState.triggered,
    );

    debugPrint('RAKSHAK SAFETY CONTROLLER: Incident created $_currentIncident');

    debugPrint('RAKSHAK SAFETY CONTROLLER: Session created $_currentSession');

    debugPrint(
      'RAKSHAK SAFETY CONTROLLER: Current state = ${stateMachine.state}',
    );
  }
 void _handleProductionTrigger(RakshakSafetyEvent event) {
  debugPrint(
    'RAKSHAK SAFETY CONTROLLER: Production SOS trigger approved',
  );

  if (state != RakshakSafetyState.safe) {
    debugPrint(
      'RAKSHAK SAFETY CONTROLLER: Ignoring production trigger because current state is $state',
    );
    return;
  }

  final transitioned = stateMachine.transitionTo(
    RakshakSafetyState.triggered,
  );

  if (!transitioned) {
    debugPrint(
      'RAKSHAK SAFETY CONTROLLER: Failed to transition production SOS to TRIGGERED',
    );
    return;
  }

  final now = DateTime.now();

  _currentIncident = RakshakIncident(
    id: 'incident_${now.microsecondsSinceEpoch}',
    createdAt: now,
    triggerType: event.type,
    triggerSource: event.source,
    state: RakshakSafetyState.triggered,
    lastUpdatedAt: now,
  );

  final trigger = triggerClassifier.classify(
    type: event.type,
    source: event.source,
  );

  _currentSession = RakshakSafetySession(
    sessionId: _currentIncident!.id,
    startedAt: now,
    triggerType: trigger.name,
    triggerSource: event.source,
    state: RakshakSafetyState.triggered,
  );

  debugPrint(
    'RAKSHAK SAFETY CONTROLLER: Production incident created $_currentIncident',
  );

  debugPrint(
    'RAKSHAK SAFETY CONTROLLER: Production session created $_currentSession',
  );

  debugPrint(
    'RAKSHAK SAFETY CONTROLLER: Production SOS state = ${stateMachine.state}',
  );
}
  RakshakTrustedContactAction prepareTestAlert({
  RakshakLocationSnapshot? location,
  bool trustedContactsAvailable = false,
  List<String> trustedContactIds = const [],
})
  {
    debugPrint('RAKSHAK CONTROLLER: Preparing test alert');

    final alertAction = alertOrchestrator.prepareTestAlert(
  location: location,
  trustedContactsAvailable: trustedContactsAvailable,
  trustedContactIds: trustedContactIds,
);
    debugPrint('RAKSHAK ALERT ACTION: $alertAction');

    return alertAction;
  }

  void runSafetyIntelligenceTest() {
    debugPrint('RAKSHAK SAFETY INTELLIGENCE TEST: START');

    if (state != RakshakSafetyState.safe) {
      debugPrint('INTELLIGENCE TEST: Expected SAFE, got $state');
      return;
    }

    final event = RakshakSafetyEvent(
      type: 'test_safety_event',
      message: 'Safety intelligence test',
      timestamp: DateTime.now(),
      source: 'intelligence_test',
    );

    handleEvent(event);

    if (state != RakshakSafetyState.triggered) {
      debugPrint('INTELLIGENCE TEST: Trigger failed');
      reset();
      return;
    }

    debugPrint('INTELLIGENCE TEST: TRIGGERED');

    final testLocation = RakshakLocationSnapshot(
      latitude: 17.4948,
      longitude: 78.3996,
      accuracy: 10.0,
      capturedAt: DateTime.now(),
    );

    final evaluation = evaluateSafety(
      isTestMode: true,
      userResponded: false,
      location: testLocation,
      trustedContactsAvailable: true,
    );

    debugPrint('INTELLIGENCE TEST: Evaluation=$evaluation');

    if (state != RakshakSafetyState.evaluating) {
      debugPrint('INTELLIGENCE TEST: Evaluation state failed, got $state');
      reset();
      return;
    }

    final alerting = beginAlerting();

    if (!alerting || state != RakshakSafetyState.alerting) {
      debugPrint('INTELLIGENCE TEST: Alerting failed, got $state');
      reset();
      return;
    }

    final action = prepareTestAlert(
      location: testLocation,
      trustedContactsAvailable: true,
    );

    debugPrint('INTELLIGENCE TEST: Prepared action=$action');

    final resolved = resolve();

    if (!resolved || state != RakshakSafetyState.resolved) {
      debugPrint('INTELLIGENCE TEST: Resolve failed, got $state');
      reset();
      return;
    }

    final safe = returnToSafe();

    if (!safe || state != RakshakSafetyState.safe) {
      debugPrint('INTELLIGENCE TEST: Return to SAFE failed, got $state');
      reset();
      return;
    }

    debugPrint('RAKSHAK SAFETY INTELLIGENCE TEST: COMPLETE');

    debugPrint('RAKSHAK SAFETY INTELLIGENCE TEST: Final state=$state');
  }

void runEvaluatorScenarioTest() {
    debugPrint('RAKSHAK EVALUATOR SCENARIO TEST: START');

    evaluator.runTestScenarios();

    debugPrint('RAKSHAK EVALUATOR SCENARIO TEST: COMPLETE');
  }

  bool evaluateSafety({
    bool isTestMode = true,
    bool userResponded = false,
    RakshakLocationSnapshot? location,
    bool trustedContactsAvailable = false,
  }) {
    debugPrint('RAKSHAK SAFETY CONTROLLER: Starting safety evaluation');

    final context = contextBuilder.build(
      isTestMode: isTestMode,
      userResponded: userResponded,
      location: location,
      trustedContactsAvailable: trustedContactsAvailable,
    );

    final result = evaluator.evaluate(context);

    debugPrint('RAKSHAK EVALUATION RESULT: $result');

    if (result.decision == RakshakEvaluationDecision.resolve) {
      debugPrint('RAKSHAK SAFETY CONTROLLER: Evaluation requested RESOLVE');

      return resolve();
    }

    final success = lifecycle.evaluate();

    if (success && _currentIncident != null) {
      final now = DateTime.now();

      _currentIncident = _currentIncident!.copyWith(
        state: stateMachine.state,
        lastUpdatedAt: now,
      );
    }

    return success;
  }

  bool beginAlerting() {
    final success = lifecycle.beginAlerting();

    if (success && _currentIncident != null) {
      final now = DateTime.now();

      _currentIncident = _currentIncident!.copyWith(
        state: RakshakSafetyState.alerting,
        lastUpdatedAt: now,
      );

      debugPrint(
        'RAKSHAK SAFETY CONTROLLER: Incident state=${_currentIncident!.state}',
      );
    }

    return success;
  }

  bool resolve() {
    final success = lifecycle.resolve();

    if (success && _currentIncident != null) {
      final now = DateTime.now();

      _currentIncident = _currentIncident!.copyWith(
        state: RakshakSafetyState.resolved,
        lastUpdatedAt: now,
      );

      debugPrint(
        'RAKSHAK SAFETY CONTROLLER: Incident state=${_currentIncident!.state}',
      );
    }

    return success;
  }

  bool returnToSafe() {
    final success = lifecycle.returnToSafe();

    if (success && _currentIncident != null) {
      debugPrint(
        'RAKSHAK SAFETY CONTROLLER: Returned incident ${_currentIncident!.id} to SAFE',
      );

      _currentIncident = _currentIncident!.copyWith(
        state: RakshakSafetyState.safe,
        lastUpdatedAt: DateTime.now(),
      );
    }

    return success;
  }

  void reset() {
    stateMachine.reset();

    _currentIncident = null;
    _currentSession = null;

    debugPrint(
      'RAKSHAK SAFETY CONTROLLER: Reset complete. Current state = ${stateMachine.state}',
    );
  }

  void runTestLifecycle() {
    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: START');

    if (state != RakshakSafetyState.safe) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Expected SAFE, got $state',
      );
      return;
    }

    final testEvent = RakshakSafetyEvent(
      type: 'test_safety_event',
      message: 'Controller lifecycle test',
      timestamp: DateTime.now(),
      source: 'controller_lifecycle_test',
    );

    handleEvent(testEvent);

    if (state != RakshakSafetyState.triggered) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Expected TRIGGERED, got $state',
      );
      return;
    }

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: TRIGGERED');

    final evaluated = lifecycle.evaluate();

    if (!evaluated || state != RakshakSafetyState.evaluating) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Evaluation failed, state=$state',
      );
      return;
    }

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: EVALUATING');

    final alerting = beginAlerting();

    if (!alerting || state != RakshakSafetyState.alerting) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Alerting failed, state=$state',
      );
      return;
    }

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: ALERTING');

    final resolved = resolve();

    if (!resolved || state != RakshakSafetyState.resolved) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Resolve failed, state=$state',
      );
      return;
    }

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: RESOLVED');

    final safe = returnToSafe();

    if (!safe || state != RakshakSafetyState.safe) {
      debugPrint(
        'RAKSHAK CONTROLLER LIFECYCLE TEST: Return to SAFE failed, state=$state',
      );
      return;
    }

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: SAFE');

    debugPrint('RAKSHAK CONTROLLER LIFECYCLE TEST: COMPLETE');
  }

  RakshakDispatchResult dispatchTestAlert(
    RakshakTrustedContactAction action,
  ) {
    debugPrint('📤 RAKSHAK CONTROLLER: Dispatching TEST alert');

    final result = testAlertDispatcher.dispatch(action);

    debugPrint('📬 RAKSHAK TEST DISPATCH RESULT: $result');

    return result;
  }
 RakshakTrustedContactAction? prepareProductionAlert({
  required RakshakLocationSnapshot location,
  required bool trustedContactsAvailable,
  List<String> trustedContactIds = const [],
  List<RakshakAlertRecipient> recipients = const [],
}) {
  if (state != RakshakSafetyState.triggered &&
      state != RakshakSafetyState.evaluating &&
      state != RakshakSafetyState.alerting) {
    debugPrint(
      'RAKSHAK SAFETY CONTROLLER: Cannot prepare production alert from state $state',
    );
    return null;
  }

  final alertAction = alertOrchestrator.prepareProductionAlert(
  location: location,
  trustedContactsAvailable: trustedContactsAvailable,
  trustedContactIds: trustedContactIds,
  recipients: recipients,
);

  debugPrint(
    'RAKSHAK SAFETY CONTROLLER: Production alert prepared',
  );

  debugPrint(
    'RAKSHAK PRODUCTION ALERT ACTION: $alertAction',
  );
  return alertAction;
}
}










