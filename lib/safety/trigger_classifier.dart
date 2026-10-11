import 'package:flutter/foundation.dart';

enum RakshakTriggerType { voice, sosButton, backgroundService, test, unknown }

class RakshakTriggerClassifier {
  const RakshakTriggerClassifier();

  RakshakTriggerType classify({required String type, required String source}) {
    debugPrint(
      '🧭 RAKSHAK TRIGGER CLASSIFIER: '
      'type=$type source=$source',
    );

    if (type == 'test_safety_event') {
      return RakshakTriggerType.test;
    }

    if (source.contains('voice')) {
      return RakshakTriggerType.voice;
    }

    if (source.contains('sos')) {
      return RakshakTriggerType.sosButton;
    }

    if (source.contains('foreground_service')) {
      return RakshakTriggerType.backgroundService;
    }

    return RakshakTriggerType.unknown;
  }
}
