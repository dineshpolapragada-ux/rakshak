import 'package:flutter/foundation.dart';

import 'alert_payload.dart';
import 'alert_recipient.dart';
import 'location_snapshot.dart';
import 'trusted_contact_action.dart';

class RakshakAlertOrchestrator {
  const RakshakAlertOrchestrator();

  RakshakTrustedContactAction prepareTestAlert({
    RakshakLocationSnapshot? location,
    required bool trustedContactsAvailable,
    List<String> trustedContactIds = const [],
    List<RakshakAlertRecipient> recipients = const [],
  }) {
    debugPrint(
      '📣 RAKSHAK ALERT ORCHESTRATOR: Preparing TEST alert',
    );

    final payload = RakshakAlertPayload(
      title: 'Rakshak Test SOS',
      message: 'This is a TEST safety alert from Rakshak.',
      location: location,
      timestamp: DateTime.now(),
      trustedContactIds: trustedContactIds,
      recipients: recipients,
      testMode: true,
    );

    debugPrint('📦 TEST ALERT PAYLOAD: $payload');

    return RakshakTrustedContactAction(
      type: RakshakTrustedContactActionType.prepareTestAlert,
      description: 'Prepare trusted-contact alert in TEST MODE only',
      testMode: true,
      location: location,
      payload: payload,
    );
  }

  RakshakTrustedContactAction prepareProductionAlert({
    RakshakLocationSnapshot? location,
    required bool trustedContactsAvailable,
    List<String> trustedContactIds = const [],
    List<RakshakAlertRecipient> recipients = const [],
  }) {
    debugPrint(
      '📣 RAKSHAK ALERT ORCHESTRATOR: Preparing PRODUCTION alert',
    );

    final payload = RakshakAlertPayload(
      title: 'Rakshak SOS Alert',
      message:
          'A Rakshak SOS has been activated. Please check on the user immediately.',
      location: location,
      timestamp: DateTime.now(),
      trustedContactIds: trustedContactIds,
      recipients: recipients,
      testMode: false,
    );

    debugPrint('📦 PRODUCTION ALERT PAYLOAD: $payload');

    return RakshakTrustedContactAction(
      type: RakshakTrustedContactActionType.notify,
      description: 'Prepare trusted-contact alert in PRODUCTION MODE',
      testMode: false,
      location: location,
      payload: payload,
    );
  }
}
