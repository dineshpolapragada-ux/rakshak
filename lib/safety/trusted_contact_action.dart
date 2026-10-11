import 'package:flutter/foundation.dart';

import 'alert_payload.dart';
import 'location_snapshot.dart';

enum RakshakTrustedContactActionType {
  prepareTestAlert,
  notify,
  call,
}

@immutable
class RakshakTrustedContactAction {
  final RakshakTrustedContactActionType type;
  final String description;
  final bool testMode;
  final RakshakLocationSnapshot? location;
  final RakshakAlertPayload? payload;

  const RakshakTrustedContactAction({
    required this.type,
    required this.description,
    required this.testMode,
    this.location,
    this.payload,
  });

  @override
  String toString() {
    return 'RakshakTrustedContactAction('
        'type: $type, '
        'description: $description, '
        'testMode: $testMode, '
        'location: $location, '
        'payload: $payload'
        ')';
  }
}