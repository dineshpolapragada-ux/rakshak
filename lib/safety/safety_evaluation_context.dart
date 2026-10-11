import 'package:flutter/foundation.dart';

@immutable
class RakshakSafetyEvaluationContext {
  final bool isTestMode;
  final bool userResponded;
  final bool locationAvailable;
  final bool trustedContactsAvailable;

  const RakshakSafetyEvaluationContext({
    required this.isTestMode,
    required this.userResponded,
    required this.locationAvailable,
    required this.trustedContactsAvailable,
  });

  @override
  String toString() {
    return 'RakshakSafetyEvaluationContext('
        'isTestMode: $isTestMode, '
        'userResponded: $userResponded, '
        'locationAvailable: $locationAvailable, '
        'trustedContactsAvailable: $trustedContactsAvailable'
        ')';
  }
}
