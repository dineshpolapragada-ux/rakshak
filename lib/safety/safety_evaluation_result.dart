import 'package:flutter/foundation.dart';

enum RakshakEvaluationDecision { continueToAlert, resolve }

@immutable
class RakshakSafetyEvaluationResult {
  final RakshakEvaluationDecision decision;
  final String reason;
  final DateTime evaluatedAt;

  const RakshakSafetyEvaluationResult({
    required this.decision,
    required this.reason,
    required this.evaluatedAt,
  });

  @override
  String toString() {
    return 'RakshakSafetyEvaluationResult('
        'decision: $decision, '
        'reason: $reason, '
        'evaluatedAt: $evaluatedAt'
        ')';
  }
}
