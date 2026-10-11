import 'package:flutter/foundation.dart';

@immutable
class RakshakDeliveryEligibility {
  final bool eligible;
  final String reason;

  const RakshakDeliveryEligibility({
    required this.eligible,
    required this.reason,
  });

  @override
  String toString() {
    return 'RakshakDeliveryEligibility('
        'eligible: $eligible, '
        'reason: $reason'
        ')';
  }
}
