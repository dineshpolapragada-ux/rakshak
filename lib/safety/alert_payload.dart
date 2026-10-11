import 'package:flutter/foundation.dart';

import 'alert_recipient.dart';
import 'location_snapshot.dart';

@immutable
class RakshakAlertPayload {
  final String title;
  final String message;
  final RakshakLocationSnapshot? location;
  final DateTime timestamp;
  final List<String> trustedContactIds;
  final List<RakshakAlertRecipient> recipients;
  final bool testMode;

  const RakshakAlertPayload({
    required this.title,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.trustedContactIds,
    required this.recipients,
    required this.testMode,
  });

  @override
  String toString() {
    return 'RakshakAlertPayload('
        'title: $title, '
        'message: $message, '
        'location: $location, '
        'timestamp: $timestamp, '
        'trustedContactIds: $trustedContactIds, '
        'recipients: $recipients, '
        'testMode: $testMode'
        ')';
  }
}
