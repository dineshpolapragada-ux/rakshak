import 'package:flutter/foundation.dart';

import 'alert_dispatcher.dart';
import 'trusted_contact_action.dart';
import 'alert_delivery_channel.dart';
import 'production_config.dart';
import 'delivery_eligibility_checker.dart';

class RakshakProductionAlertDispatcher
    implements RakshakAlertDispatcher {
  final RakshakAlertDeliveryChannel deliveryChannel;
  final RakshakDeliveryEligibilityChecker eligibilityChecker;

  const RakshakProductionAlertDispatcher({
    this.deliveryChannel = const RakshakDryRunDeliveryChannel(),
    this.eligibilityChecker =
        const RakshakDeliveryEligibilityChecker(),
  });

  @override
  RakshakDispatchResult dispatch(
    RakshakTrustedContactAction action,
  ) {
    debugPrint('🚨 RAKSHAK PRODUCTION DISPATCHER');

    if (action.testMode) {
      return RakshakDispatchResult(
        delivered: false,
        message: 'Production dispatcher rejected a TEST action.',
        dispatchedAt: DateTime.now(),
      );
    }

    if (action.type != RakshakTrustedContactActionType.notify) {
      return RakshakDispatchResult(
        delivered: false,
        message: 'Unsupported production action type.',
        dispatchedAt: DateTime.now(),
      );
    }

    final payload = action.payload;

    if (payload == null) {
      return RakshakDispatchResult(
        delivered: false,
        message: 'Production alert payload is missing.',
        dispatchedAt: DateTime.now(),
      );
    }

    final eligibility = eligibilityChecker.check(payload);

    debugPrint(
      '🔎 RAKSHAK DELIVERY ELIGIBILITY: $eligibility',
    );

    if (!eligibility.eligible) {
      return RakshakDispatchResult(
        delivered: false,
        message: eligibility.reason,
        dispatchedAt: DateTime.now(),
      );
    }

    if (!RakshakProductionConfig.realDeliveryEnabled) {
      debugPrint(
        '🛑 RAKSHAK: Real delivery is disabled by production configuration.',
      );

      return RakshakDispatchResult(
        delivered: false,
        message: 'Real delivery is disabled. Dry-run mode remains active.',
        dispatchedAt: DateTime.now(),
      );
    }

    final deliveryResult = deliveryChannel.deliver(payload);

    debugPrint(
      '📬 RAKSHAK DELIVERY RESULT: $deliveryResult',
    );

    return RakshakDispatchResult(
      delivered:
          deliveryResult.status == RakshakDeliveryStatus.delivered,
      message: deliveryResult.message,
      dispatchedAt: deliveryResult.timestamp,
    );
  }
}
