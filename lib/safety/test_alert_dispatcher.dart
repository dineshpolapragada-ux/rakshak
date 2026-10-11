import 'package:flutter/foundation.dart';

import 'alert_dispatcher.dart';
import 'trusted_contact_action.dart';

class RakshakTestAlertDispatcher implements RakshakAlertDispatcher {
  const RakshakTestAlertDispatcher();

  @override
  RakshakDispatchResult dispatch(
    RakshakTrustedContactAction action,
  ) {
    debugPrint('RAKSHAK TEST DISPATCHER: Starting');

    if (!action.testMode) {
      debugPrint(
        'RAKSHAK TEST DISPATCHER: Rejected because action is not TEST MODE',
      );

      return RakshakDispatchResult(
        delivered: false,
        message: 'Dispatch rejected: action is not in TEST MODE.',
        dispatchedAt: DateTime.now(),
      );
    }

    final payload = action.payload;

    if (payload == null) {
      debugPrint(
        'RAKSHAK TEST DISPATCHER: Rejected because payload is missing',
      );

      return RakshakDispatchResult(
        delivered: false,
        message: 'Dispatch rejected: alert payload is missing.',
        dispatchedAt: DateTime.now(),
      );
    }

    debugPrint('TEST DISPATCH PAYLOAD: $payload');
    debugPrint(
      'TEST DISPATCH CONTACT IDS: ${payload.trustedContactIds}',
    );

    return RakshakDispatchResult(
      delivered: true,
      message: 'TEST alert successfully simulated.',
      dispatchedAt: DateTime.now(),
    );
  }
}
