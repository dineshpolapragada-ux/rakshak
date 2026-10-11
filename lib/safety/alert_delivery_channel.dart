import 'package:flutter/foundation.dart';

import 'alert_payload.dart';

enum RakshakDeliveryStatus {
  delivered,
  failed,
  unavailable,
}

class RakshakDeliveryResult {
  final RakshakDeliveryStatus status;
  final String message;
  final DateTime timestamp;

  const RakshakDeliveryResult({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RakshakDeliveryResult('
        'status: $status, '
        'message: $message, '
        'timestamp: $timestamp'
        ')';
  }
}

abstract class RakshakAlertDeliveryChannel {
  const RakshakAlertDeliveryChannel();

  RakshakDeliveryResult deliver(
    RakshakAlertPayload payload,
  );
}

class RakshakDryRunDeliveryChannel
    implements RakshakAlertDeliveryChannel {
  const RakshakDryRunDeliveryChannel();

  @override
  RakshakDeliveryResult deliver(
    RakshakAlertPayload payload,
  ) {
    debugPrint('🧪 RAKSHAK DELIVERY CHANNEL: DRY RUN');
    debugPrint('📦 Delivery payload: $payload');

    return RakshakDeliveryResult(
      status: RakshakDeliveryStatus.delivered,
      message: 'Alert delivery validated successfully (DRY RUN).',
      timestamp: DateTime.now(),
    );
  }
}