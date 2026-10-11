import 'package:flutter/foundation.dart';

import 'safety_evaluation_context.dart';
import 'safety_evaluation_result.dart';

class RakshakSafetyEvaluator {
  const RakshakSafetyEvaluator();

  RakshakSafetyEvaluationResult evaluate(
    RakshakSafetyEvaluationContext context,
  ) {
    debugPrint('🔎 RAKSHAK SAFETY EVALUATOR: Starting evaluation');

    debugPrint('🧠 RAKSHAK EVALUATION CONTEXT: $context');

    if (context.isTestMode) {
      debugPrint('🧪 RAKSHAK SAFETY EVALUATOR: TEST MODE detected');

      return RakshakSafetyEvaluationResult(
        decision: RakshakEvaluationDecision.continueToAlert,
        reason: 'Test event accepted for alert pipeline simulation',
        evaluatedAt: DateTime.now(),
      );
    }

    if (context.userResponded) {
      debugPrint(
        '✅ RAKSHAK SAFETY EVALUATOR: '
        'User response detected',
      );

      return RakshakSafetyEvaluationResult(
        decision: RakshakEvaluationDecision.resolve,
        reason: 'User responded to the safety check',
        evaluatedAt: DateTime.now(),
      );
    }

    if (!context.locationAvailable) {
      debugPrint(
        '⚠️ RAKSHAK SAFETY EVALUATOR: '
        'Location unavailable',
      );
    }

    if (!context.trustedContactsAvailable) {
      debugPrint(
        '⚠️ RAKSHAK SAFETY EVALUATOR: '
        'No trusted contacts available',
      );
    }

    return RakshakSafetyEvaluationResult(
      decision: RakshakEvaluationDecision.continueToAlert,
      reason: 'Safety conditions require continued evaluation',
      evaluatedAt: DateTime.now(),
    );
  }

  void runTestScenarios() {
    debugPrint('🧪 RAKSHAK EVALUATOR SCENARIO TEST: START');

    final scenarios = <String, RakshakSafetyEvaluationContext>{
      'TEST MODE': const RakshakSafetyEvaluationContext(
        isTestMode: true,
        userResponded: false,
        locationAvailable: false,
        trustedContactsAvailable: false,
      ),
      'USER RESPONDED': const RakshakSafetyEvaluationContext(
        isTestMode: false,
        userResponded: true,
        locationAvailable: true,
        trustedContactsAvailable: true,
      ),
      'NO RESPONSE': const RakshakSafetyEvaluationContext(
        isTestMode: false,
        userResponded: false,
        locationAvailable: true,
        trustedContactsAvailable: true,
      ),
      'NO LOCATION': const RakshakSafetyEvaluationContext(
        isTestMode: false,
        userResponded: false,
        locationAvailable: false,
        trustedContactsAvailable: true,
      ),
      'NO CONTACTS': const RakshakSafetyEvaluationContext(
        isTestMode: false,
        userResponded: false,
        locationAvailable: true,
        trustedContactsAvailable: false,
      ),
    };

    for (final entry in scenarios.entries) {
      final result = evaluate(entry.value);

      debugPrint('🧪 SCENARIO — ${entry.key}: $result');
    }

    debugPrint('🧪 RAKSHAK EVALUATOR SCENARIO TEST: COMPLETE');
  }
}
