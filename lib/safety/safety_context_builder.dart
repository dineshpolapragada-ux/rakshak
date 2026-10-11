import 'package:flutter/foundation.dart';

import 'location_snapshot.dart';
import 'safety_evaluation_context.dart';

class RakshakSafetyContextBuilder {
  const RakshakSafetyContextBuilder();

  RakshakSafetyEvaluationContext build({
    required bool isTestMode,
    required bool userResponded,
    RakshakLocationSnapshot? location,
    required bool trustedContactsAvailable,
  }) {
    final context = RakshakSafetyEvaluationContext(
      isTestMode: isTestMode,
      userResponded: userResponded,
      locationAvailable: location != null,
      trustedContactsAvailable: trustedContactsAvailable,
    );

    debugPrint('🧠 RAKSHAK CONTEXT BUILDER: $context');

    if (location != null) {
      debugPrint(
        '📍 RAKSHAK LOCATION: '
        '${location.latitude}, ${location.longitude} '
        '(accuracy=${location.accuracy})',
      );
    } else {
      debugPrint('📍 RAKSHAK LOCATION: unavailable');
    }

    debugPrint(
      '👥 RAKSHAK TRUSTED CONTACTS: '
      '$trustedContactsAvailable',
    );

    return context;
  }
}
